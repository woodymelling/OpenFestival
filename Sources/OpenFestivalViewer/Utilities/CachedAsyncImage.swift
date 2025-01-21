//import Nuke
//import SwiftUI
//import NonEmpty
//
//struct CachedAsyncImage<I: View, P: View>: View {
//
//    @Observable
//    class Model {
//        #if canImport(SwiftUI)
//        public var image: Image? {
//            #if os(macOS)
//            platformImage.map { Image(nsImage: $0) }
//            #else
//            platformImage.map { Image(uiImage: $0) }
//            #endif
//        }
//        #endif
//
//        private var platformImage: PlatformImage?
//        private var displayedURLOffset: Int = .max
//
//
//        func task(requests: [ImageRequest], imagePipeline: ImagePipeline) async {
//
//            let validRequests = requests.filter { $0.url != nil }
//            guard !validRequests.isEmpty else { return }
//
//            let cached = validRequests
//                .lazy
//                .enumerated()
//                .compactMap({ enumerated in
//                    imagePipeline.cache[enumerated.element]
//                        .map { (element: $0, offset: enumerated.offset)} })
//                .first
//
//            if let cached {
//                self.platformImage = cached.element.image
//                self.displayedURLOffset = cached.offset
//            }
//
//            try? await Task.sleep(for: .seconds(5))
//
//            await withTaskGroup(of: (offset: Int, result: PlatformImage?).self) { group in
//                for request in validRequests.enumerated() {
//                    group.addTask {
//                        let fetchedImage = try? await imagePipeline.image(for: request.element)
//                        return (request.offset, fetchedImage)
//                    }
//                }
//
//                for await (offset, image) in group {
//                    if let image, offset < displayedURLOffset {
//                        self.displayedURLOffset = offset
//                        self.platformImage = image
//                    }
//                }
//            }
//        }
//    }
//
//
//    init(
//        request requests: ImageRequest...,
//        @ViewBuilder content: @escaping (Image) -> I = { $0 },
//        @ViewBuilder placeholder: () -> P
//    ) {
//        self.requests = requests
//        self.content = content
//        self.placeholder = placeholder()
//    }
//
//    init(
//        url urls: URL?...,
//        @ViewBuilder content: @escaping (Image) -> I = { $0 },
//        @ViewBuilder placeholder: () -> P
//    ) {
//        self.requests = urls.map { ImageRequest(url: $0) }
//        self.content = content
//        self.placeholder = placeholder()
//    }
//
//    var requests: [ImageRequest]
//    var content: (Image) -> I
//    var placeholder: P
//
//    @State var model = Model()
//
//
//    @Environment(\.imagePipeline) var imagePipeline
//
//    var body: some View {
//        Group {
//            if let image = model.image {
//                content(image)
//            } else {
//                placeholder
//            }
//        }
//        .task { await model.task(requests: requests, imagePipeline: imagePipeline) }
//    }
//}
//
//extension EnvironmentValues {
//    @Entry var imagePipeline: ImagePipeline = .shared
//}
//
//import OpenFestivalModels
//
//#Preview {
//    List {
//        ForEach(0..<10, id: \.self) { _ in
//
//            CachedAsyncImage(url: Event.testival.artists.first!.imageURL) {
//                $0
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
//                    .frame(height: 50)
//            } placeholder: {
//                ProgressView()
//            }
//        }
//    }
//
//}
