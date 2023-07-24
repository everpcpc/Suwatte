//
//  DV+Settings.swift
//  Suwatte (iOS)
//
//  Created by Mantton on 2023-06-24.
//

import SwiftUI

extension DirectoryViewer {
    struct SettingsSheet: View {
        @AppStorage(STTKeys.LocalThumnailOnly) var showOnlyThumbs = false
        @AppStorage(STTKeys.LocalHideInfo) var showTitleOnly = false
        var body: some View {
            NavigationView {
                List {
                    Section {
                        Toggle("Show Only Thumbnails", isOn: $showOnlyThumbs)
                        if !showOnlyThumbs {
                            Toggle("Hide Content Insight", isOn: $showTitleOnly)
                                .transition(.opacity)
                        }
                    } header: {
                        Text("Layout")
                    }
                }
                .closeButton()
                .navigationTitle("Settings")
                .animation(.default, value: showOnlyThumbs)
                .animation(.default, value: showTitleOnly)
            }
            .navigationViewStyle(.stack)
        }
    }
}
