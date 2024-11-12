//
//  Untitled.swift
//  OpenFestival
//
//  Created by Woodrow Melling on 11/9/24.
//

import SwiftUI
import UniformTypeIdentifiers

extension EnvironmentValues {
    @Entry var allowReordering = true
}

public struct ReorderableForEach<Data: Identifiable, Content: View>: View {

    public init(
        _ data: Binding<[Data]>,
        @ViewBuilder content: @escaping (Data, Bool) -> Content
    ) {
        self._data = data
        self.content = content
    }

    @Binding var data: [Data]
    let content: (Data, _ isDragging: Bool) -> Content

    @State private var draggedItem: Data.ID?
    @Environment(\.allowReordering) var allowReordering

    public var body: some View {
        ForEach(data) { item in
            if allowReordering {
                content(item, draggedItem == item.id)
                    .onDrag {
                        draggedItem = item.id
                        return NSItemProvider(object: "\(item.id.hashValue)" as NSString)
                    }
                    .onDrop(of: [UTType.plainText], delegate: DragRelocateDelegate(
                        item: item,
                        data: $data,
                        draggedItem: $draggedItem
                    ))
            } else {
                content(item, false)
            }
        }
    }
}


struct DragRelocateDelegate<Data: Identifiable>: DropDelegate {
    let item: Data
    @Binding var data: [Data]
    @Binding var draggedItem: Data.ID?

    func dropEntered(info: DropInfo) {
        print("DROPPEDENTERED")
        guard item.id != draggedItem,
              let current = draggedItem,
              let from = data.firstIndex(where: { $0.id == current }),
              let destination = data.firstIndex(where: { $0.id == item.id })
        else {
            return
        }

        if data[destination].id != current {
            withAnimation(.snappy) {
                data.move(
                    fromOffsets: IndexSet(integer: from),
                    toOffset: (destination > from) ? destination + 1 : destination
                )
            }
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedItem = nil
        return true
    }
}

struct ReorderingVStackTest: View {

    struct Tab: Identifiable {
        init(name: String) {
            self.name = name
        }
        var id = UUID()
        var name: String
    }
    @State private var data = ["Apple", "Orange", "Banana", "Lemon", "Tangerine"].map(Tab.init(name:))
    @State var allowReordering = false

    var body: some View {
        VStack {
            Toggle("Allow reordering", isOn: $allowReordering)
                .frame(width: 200)
                .padding(.bottom, 30)

            ScrollView(.horizontal) {
                HStack {
                    ReorderableForEach($data) { item, _ in
                        Text(item.name)
                            .font(.title)
                            .padding()
                            .frame(minWidth: 200, minHeight: 50)
                            .border(Color.blue)
                            .background(Color.red.opacity(0.9))

                    }
                }
            }
        }
    }
}
struct ReorderingVStackTest_Previews: PreviewProvider {
    static var previews: some View {
        ReorderingVStackTest()
    }
}
