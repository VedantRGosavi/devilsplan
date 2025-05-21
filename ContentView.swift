//
//  ContentView.swift
//  DevilsPlan
//
//  Created by Vedant Gosavi on 5/20/25.
//


import SwiftUI
import Clerk

struct ContentView: View {
  @Environment(Clerk.self) private var clerk

  var body: some View {
    NavigationView {
      VStack {
        if let user = clerk.user {
          HomeView()
        } else {
          SignUpOrSignInView()
        }
      }
    }
  }
}

#Preview {
  ContentView()
    .environment(Clerk())
}
