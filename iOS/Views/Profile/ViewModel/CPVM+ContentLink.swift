//
//  CPVM+ContentLink.swift
//  Suwatte (iOS)
//
//  Created by Mantton on 2023-08-23.
//

import Foundation

fileprivate typealias ViewModel = ProfileView.ViewModel


extension ViewModel {
    // Handles the addition on linked chapters
    func resolveLinks() async {
        let id = identifier
        let actor = await RealmActor()
        // Contents that this title is linked to
        let entries = await actor
            .getLinkedContent(for: id)

        linkedContentIDs = entries
            .map(\.id)

        // Ensure there are linked titles
        guard !entries.isEmpty, !Task.isCancelled else { return }

        let groups = await withTaskGroup(of: ContentLinkSection?.self, body: { group in
            for entry in entries {
                group.addTask { [weak self] in
                    await self?.getChapterSection(for: entry)
                }
            }
            
            var sections = [ContentLinkSection]()
            for await result in group {
                guard let result else { continue }
                sections.append(result)
            }
            
            return sections
        })
                
        await animate { [weak self] in
            self?.linked = groups
        }
    }
    
    func getChapterSection(for content: StoredContent) async -> ContentLinkSection? {
        let source = await DSK.shared.getSource(id: content.sourceId)
        guard let source else { return nil }
        do {
            let chapters = try await source.getContentChapters(contentId: content.contentId)
            let prepared = chapters
                .sorted(by: \.index, descending: false)
                .map { $0.toThreadSafe(sourceID: content.sourceId, contentID: content.contentId) }
            
            Task {
                let actor = await RealmActor()
                let stored = prepared
                    .map { $0.toStored() }
                await actor.storeChapters(stored)
            }
            
            let maxOrderKey = prepared
                .max(by: \.chapterOrderKey)?
                .chapterOrderKey ?? 0
            
            return .init(source: source,
                         chapters: prepared,
                         maxOrderKey: maxOrderKey)

        } catch {
            Logger.shared.error(error, source.id)
        }
        
        return nil
    }
    
    func updateContentLinks() async {
        let actor = await RealmActor()
        let newLinked = await actor.getLinkedContent(for: identifier).map(\.id)
        guard newLinked != linkedContentIDs else { return }
        await MainActor.run { [weak self] in
            self?.contentState = .idle
            self?.chapterState = .idle
        }
    }
}

extension Sequence {
    func max<T: Comparable>(by keyPath: KeyPath<Element, T>) -> Element? {
        return self.max { a, b in
            return a[keyPath: keyPath] < b[keyPath: keyPath]
        }
    }
}
