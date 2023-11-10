//
//  ViewModifiers.swift
//  TestSpeech
//
//  Created by Kostyantin on 06.11.2023.
//
import SwiftUI

struct BackgroundColorStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    func body(content: Content) -> some View {
        let startColor: Color
        let endColor: Color

        if colorScheme == .light {
            startColor = Color(#colorLiteral(red: 0.1647058824, green: 0.1764705882, blue: 0.1960784314, alpha: 1))
            endColor = Color(#colorLiteral(red: 0.131372549, green: 0.07450980392, blue: 0.07450980392, alpha: 1))
        } else {
            startColor = Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.24))
            endColor = Color(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0))
        }

        return content.background(
            LinearGradient(gradient: Gradient(colors: [startColor, endColor]), startPoint: .top, endPoint: .bottom)
        )
    }
}

struct CustomTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(Color(red: 250/255, green: 250/255, blue: 250/255, opacity: 0.93))
            .font(Font.custom("Anton", size: 40))
            .fontWeight(.bold)
            .lineSpacing(10)
            .padding(.horizontal, 20)
    }
}

struct CustomButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding(10)
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: 40)
                    .fill(Color(#colorLiteral(red: 0.1254901961, green: 0.1294117647, blue: 0.1294117647, alpha: 1)))
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct CustomVStackStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 40)
                    .fill(Color(#colorLiteral(red: 0.1254901961, green: 0.1294117647, blue: 0.1294117647, alpha: 1)))
            )
    }
}
