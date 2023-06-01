//
//  ReaderGateWay.swift
//  Suwatte (iOS)
//
//  Created by Mantton on 2022-05-15.
//

import SwiftUI

struct ReaderGateWay: View {
    var readingMode: ReadingMode
    var chapterList: [StoredChapter]
    var openTo: StoredChapter
    var pageIndex: Int?
    var title: String?
    @AppStorage(STTKeys.AppAccentColor) var accentColor: Color = .sttDefault
    
    var body: some View {
        Group {
            switch readingMode {
                case .NOVEL:
                    EmptyView()
                case .WEB:
                    WebReader(chapter: openTo)
                default:
                    ReaderView(model: .init(chapterList: chapterList, openTo: openTo,title: title, pageIndex: pageIndex ,readingMode: readingMode))
            }
        }
        .tint(accentColor)
        .accentColor(accentColor)
    }
}

struct WebReader: View {
    var chapter: StoredChapter
    
    var body: some View {
        NavigationView {
            STTWebView(url: URL(string: chapter.webUrl ?? ""))
                .closeButton()
                .navigationTitle(chapter.displayName)
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}
