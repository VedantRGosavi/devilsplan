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
    VStack {
      if let user = clerk.user {
        Text("Hello, \(user.id)")
        Button("Sign Out") {
          Task { try? await clerk.signOut() }
        }
      } else {
        SignUpOrSignInView()
      }
    }
  }
}
