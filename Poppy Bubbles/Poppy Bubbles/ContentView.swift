//
//  ContentView.swift
//  Poppy Bubbles
//
//  Created by Elliot Williams on 2025-06-04.
//

import SwiftUI

struct Bubble: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    var size: CGFloat
    var color: Color
}

class BubbleManager: ObservableObject {
    @Published var bubbles: [Bubble] = []
    private var bounds: CGSize = .zero
    private var timer: Timer?
    
    func setBounds(_ bounds: CGSize) {
        self.bounds = bounds
    }
    
    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] _ in
            self?.update()
        }
    }
    
    func stop() {
        timer?.invalidate()
    }
    
    func popBubble(id: UUID) {
        withAnimation(.easeOut(duration: 0.1)) {
            bubbles.removeAll(where: { $0.id == id })
        }
    }
    
    func addBubble() {
        guard bounds != .zero else { return }
        
        let size = CGFloat.random(in: 40...100)
        let x = CGFloat.random(in: size/2...(bounds.width - size/2))
        let y = bounds.height + size/2
        let velocity = CGVector(
            dx: CGFloat.random(in: -1.5...1.5),
            dy: CGFloat.random(in: -4.0...(-1.0)) // Fixed syntax error
        )
        let colors: [Color] = [
            .blue.opacity(0.7),
            .green.opacity(0.7),
            .purple.opacity(0.7),
            .pink.opacity(0.7),
            .orange.opacity(0.7)
        ]
        
        let bubble = Bubble(
            position: CGPoint(x: x, y: y),
            velocity: velocity,
            size: size,
            color: colors.randomElement() ?? .blue
        )
        
        bubbles.append(bubble)
    }
    
    private func update() {
        var updatedBubbles: [Bubble] = []
        
        for var bubble in bubbles {
            // Apply velocity
            bubble.position.x += bubble.velocity.dx
            bubble.position.y += bubble.velocity.dy
            
            // Apply gravity-like effect
            bubble.velocity.dy += 0.05
            
            // Apply drag
            bubble.velocity.dx *= 0.99
            bubble.velocity.dy *= 0.99
            
            // Boundary collisions
            if bubble.position.x <= bubble.size/2 || bubble.position.x >= bounds.width - bubble.size/2 {
                bubble.velocity.dx *= -0.8 // Reverse with energy loss
            }
            
            if bubble.position.y <= bubble.size/2 {
                bubble.velocity.dy *= -0.8 // Bounce off top
            }
            
            // Remove off-screen bubbles
            if bubble.position.y > bounds.height + 200 {
                continue
            }
            
            updatedBubbles.append(bubble)
        }
        
        bubbles = updatedBubbles
        
        // Random bubble generation
        if Int.random(in: 0...100) < 5 { // 5% chance each frame
            addBubble()
        }
    }
}

struct BubbleView: View {
    let bubble: Bubble
    let popAction: () -> Void
    
    var body: some View {
        Circle()
            .fill(bubbleGradient)
            .overlay(bubbleHighlight)
            .overlay(bubbleReflection)
            .frame(width: bubble.size, height: bubble.size)
            .position(bubble.position)
            .onTapGesture(perform: popAction)
    }
    
    // Fixed type to RadialGradient (conforms to ShapeStyle)
    private var bubbleGradient: RadialGradient {
        RadialGradient(
            gradient: Gradient(colors: [
                bubble.color,
                bubble.color.opacity(0.2)
            ]),
            center: .center,
            startRadius: 0,
            endRadius: bubble.size/2
        )
    }
    
    private var bubbleHighlight: some View {
        Circle()
            .fill(Color.white.opacity(0.6))
            .frame(width: bubble.size * 0.3, height: bubble.size * 0.3)
            .offset(x: -bubble.size * 0.2, y: -bubble.size * 0.2)
    }
    
    private var bubbleReflection: some View {
        Circle()
            .stroke(Color.white.opacity(0.4), lineWidth: 2)
            .frame(width: bubble.size * 0.8, height: bubble.size * 0.8)
    }
}

struct ContentView: View {
    @StateObject private var manager = BubbleManager()
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0.2, green: 0.5, blue: 0.9), Color(red: 0.1, green: 0.1, blue: 0.3)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ForEach(manager.bubbles) { bubble in
                BubbleView(bubble: bubble) {
                    manager.popBubble(id: bubble.id)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .gesture(
            TapGesture()
                .onEnded { _ in
                    manager.addBubble()
                }
        )
        .overlay(
            VStack {
                Text("Tap bubbles to pop them!")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(10)
                Spacer()
            }
            .padding(.top, 40)
        )
        .onAppear {
            manager.start()
        }
        .onDisappear {
            manager.stop()
        }
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        manager.setBounds(geometry.size)
                    }
                    .onChange(of: geometry.size) { newSize in
                        manager.setBounds(newSize)
                    }
            }
        )
    }
}
