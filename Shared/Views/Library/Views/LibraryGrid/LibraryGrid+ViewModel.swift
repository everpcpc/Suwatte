//
//  LibraryGrid+ViewModel.swift
//  Suwatte (iOS)
//
//  Created by Mantton on 2022-03-25.
//

import Combine
import Foundation
import RealmSwift

extension LibraryView.LibraryGrid {
    final class ViewModel: ObservableObject {
        var collection: LibraryCollection?
        var readingFlag: LibraryFlag?
        @Published var searchQuery = ""
        // Sheets
        @Published var presentOptionsSheet = false
        
        // Selections
        @Published var isSelecting = false {
            didSet {
                // Clear Selections when user exits selection mode
                if !isSelecting {
                    selectedIndexes.removeAll()
                }
            }
        }
        
        @Published var selectedIndexes: Set<Int> = []
        @Published var navSelection: LibraryEntry?
        @Published var query = ""
        @Published var library: Results<LibraryEntry>?
        private var token: NotificationToken? = nil
        
        init( collection: LibraryCollection? = nil , readingFlag: LibraryFlag? = nil) {
            self.collection = collection
            self.readingFlag = readingFlag
        }
        
        func disconnect() {
            token?.invalidate()
            token = nil
            Logger.shared.debug("Disconnected Library Observer")
        }
        
        func observe(downloadsOnly: Bool, key: KeyPath, order: SortOrder) {
            token?.invalidate()
            token = nil
            let realm = try! Realm()
            let downloads = realm
                .objects(ICDMDownloadObject.self)
                .where({ $0.status == .completed })
                .distinct(by: ["chapter.sourceId", "chapter.contentId" ])
            
            // Fetch Library
            var library = realm
                .objects(LibraryEntry.self)
                .where { $0.content != nil && $0.isDeleted == false  }
            
            // Query For Title
            if !query.isEmpty {
                library = library.filter("ANY content.additionalTitles CONTAINS[cd] %@ OR content.title CONTAINS[cd] %@ OR content.summary CONTAINS[cd] %@", query, query, query)
            }
            
            // Collection Filter
            if let collection {
                var predicates = [NSPredicate]()
                
                let idPredicate = NSPredicate(format: "ANY collections CONTAINS[cd] %@", collection.id)
                
                predicates.append(idPredicate)
                
                if let filter = collection.filter {
                    switch filter.adultContent {
                        case .both: break
                        case .only:
                            predicates.append(NSPredicate(format: "content.adultContent = true"))
                        case .none:
                            predicates.append(NSPredicate(format: "content.adultContent = false"))
                    }
                    
                    if !filter.readingFlags.isEmpty {
                        let flags = filter.readingFlags.map { $0 } as [LibraryFlag]
                        predicates.append(NSPredicate(format: "flag IN %@", flags))
                    }
                    
                    if !filter.statuses.isEmpty {
                        let statuses = filter.statuses.map { $0 } as [ContentStatus]
                        predicates.append(NSPredicate(format: "content.status IN %@", statuses))
                    }
                    
                    if !filter.sources.isEmpty {
                        let sources = filter.sources.map { $0 } as [String]
                        predicates.append(NSPredicate(format: "content.sourceId IN %@", sources))
                    }
                    
                    if !filter.textContains.isEmpty {
                        let texts = filter.textContains.map { $0 } as [String]
                        for text in texts {
                            predicates.append(NSPredicate(format: "ANY content.additionalTitles CONTAINS[cd] %@ OR content.title CONTAINS[cd] %@ OR content.summary CONTAINS[cd] %@", text, text, text))
                        }
                    }
                    
                    if !filter.contentType.isEmpty {
                        //                        let types = filter.contentType.map({ $0 }) as [ExternalContentType]
                    }
                    
                    if !filter.tagContains.isEmpty {
                        let tags = filter.tagContains.map { $0.lowercased() } as [String]
                        predicates.append(NSPredicate(format: "ANY content.properties.tags.label IN[cd] %@", tags))
                    }
                }
                
                let compound = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
                library = library
                    .filter(compound)
            }
            
            // Reading Flag Filter
            if let readingFlag {
                library = library
                    .where {
                        $0.flag == readingFlag
                    }
            }
            
            if downloadsOnly {
                let ids = downloads
                    .compactMap { $0.chapter?.contentIdentifier.id } as [String]
                library = library
                    .where {
                        $0.id.in(ids)
                    }
            }
            
            let ascending = order.ascending
            let keyPath = key.path
            library = library
                .sorted(byKeyPath: keyPath, ascending: ascending)
            
            token = library.observe({ _ in
                self.library = library.freeze()
            })
            Logger.shared.debug("Connected Library Observer")
        }
        
        func refresh() {
            
        }
    }
}
