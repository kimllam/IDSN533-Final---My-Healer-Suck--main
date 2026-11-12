//
//  IDSN533_MyHealerSuckApp.swift
//  IDSN533 MyHealerSuck
//
//  Created by Kim Lam on 11/11/26.
//

import SwiftUI

@main
struct MyHealerSucksApp: App {
    @StateObject private var game = GameManager()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView()
            }
            .environmentObject(game)
        }
    }
}
