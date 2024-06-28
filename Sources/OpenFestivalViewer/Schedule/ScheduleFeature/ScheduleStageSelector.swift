//
//  SwiftUIView.swift
//  
//
//  Created by Woody on 2/17/22.
//

import SwiftUI
import IdentifiedCollections
import OpenFestivalModels
import ComposableArchitecture

struct ScheduleStageSelector: View {
    var stages: IdentifiedArrayOf<Event.Stage>
    var selectedStage: Event.Stage.ID?
    var onSelectStage: (Event.Stage.ID) -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            HStack {
                ForEach(stages) { stage in
                    Spacer()
                    ScheduleHeaderButton(
                        stage: stage,
                        isSelected: selectedStage == stage.id,
                        onSelect: onSelectStage
                    )
                }
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(
                Color(.systemBackground).edgesIgnoringSafeArea(.top)
            )
            .shadow()
        }
    }
}

internal extension View {
    func shadow() -> some View {
        self.modifier(FestivlShadowViewModifier())
    }
}

struct FestivlShadowViewModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    func body(content: Content) -> some View {
        if colorScheme == .light {
            content.shadow(radius: 3, x: 0, y:2)
        } else {
            content.shadow(color: Color.black, radius: 3, x: 0, y: 2)
        }
    }
}


struct ScheduleHeaderButton: View {
    var stage: Event.Stage
    var isSelected: Bool
    @State var press = false
    var onSelect: (Event.Stage.ID) -> Void

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.eventColorScheme) var eventColorScheme

    var stageColor: Color {
        eventColorScheme.stageColors[stage.id]
    }

    var body: some View {
        CachedAsyncIcon(url: stage.iconImageURL) {
            Text(stage.name)
                .font(.largeTitle)
                .padding(20)
        }
        .foregroundStyle(isSelected ? .white : stageColor)
        .background {
            if isSelected {
                Circle()
                    .fill(stageColor)
                    .shadow()
            }
        }
        .frame(idealWidth: 60, idealHeight: 60)
        .frame(maxWidth: 60, maxHeight: 60)
        .scaleEffect(press ? 0.8 : 1)
        .pressAndReleaseAction(
            pressing: $press,
            animation: .easeInOut(duration: 0.05),
            onRelease: {
                #if canImport(UIKit)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                #endif
                onSelect(stage.id)

            }
        )

    }
}
//
//struct ScheduleHeaderView_Previews: PreviewProvider {
//
//    static var previews: some View {
//        PreviewWrapper()
//    }
//
//    struct PreviewWrapper: View {
//
//        @State var selectedStage = Stage.testValues[1].id
//        var body: some View {
//            ScheduleStageSelector(
//                stages: IdentifiedArray(uniqueElements: Stage.testValues),
//                selectedStage: $selectedStage
//            )
//            .previewLayout(.sizeThatFits)
//            .previewAllColorModes()
//        }
//    }
//}

struct PressAndReleaseModifier: ViewModifier {
    @Binding var pressing: Bool
    var animation: Animation? = nil
    var onRelease: () -> Void

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged{ state in

                        if let animation = animation {
                            withAnimation(animation) {
                                pressing = true
                            }
                        } else {
                            pressing = true
                        }
                    }
                    .onEnded{ _ in
                        pressing = false
                        onRelease()
                    }
            )
    }
}

extension View {
    func pressAndReleaseAction(pressing: Binding<Bool>, animation: Animation? = nil, onRelease: @escaping (() -> Void)) -> some View {
        modifier(PressAndReleaseModifier(pressing: pressing, animation: animation, onRelease: onRelease))
    }
}
