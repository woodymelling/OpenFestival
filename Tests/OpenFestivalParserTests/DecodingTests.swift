import XCTest
@testable import OpenFestivalParser
import CustomDump
import OpenFestivalModels
import Testing
import Parsing

final class YamlDecodingTests: XCTestCase {
    func testDecodingSimpleEventInfo() throws {
        let yaml = """
        version: "0.1.0" # Schema Version

        # General Information
        name: "Testival"
        address: "123 Festival Road, Music City"
        timeZone: "America/Seattle"

        # Images
        imageURL: "http://example.com/event-image.jpg"
        siteMapImageURL: "http://example.com/site-map.jpg"

        # Colors
        colorScheme:
            primaryColor: "#FF5733"
            workshopsColor: "#C70039"
        """

        let parser = Parsers.Yaml<EventInfoDTO>()

        let dto = try parser.parse(yaml)

        #expect(
            dto ==
            EventInfoDTO(
                name: "Testival",
                address: "123 Festival Road, Music City",
                timeZone: "America/Seattle",
                imageURL: URL(string: "http://example.com/event-image.jpg"),
                siteMapImageURL: URL(string: "http://example.com/site-map.jpg"),
                colorScheme: .init(primaryColor: "#FF5733", workshopsColor: "#C70039")
            )
        )
    }

    func testDecodingSimpleStageInfo() throws {
        let yaml = """
        - name: "Mystic Grove"
          color: "#1DB954"
          imageURL: "http://example.com/mystic-grove.jpg"

        - name: "Bass Haven"
          color: "#FF5733"
          imageURL: "http://example.com/bass-haven.jpg"

        - name: "Tranquil Meadow"
          color: "#4287f5"
        """

        let parser = Parsers.Yaml<[StageDTO]>()

        let dto = try parser.parse(yaml)


        #expect(
            dto ==
            [
                StageDTO(name: "Mystic Grove", color: "#1DB954", imageURL: URL(string: "http://example.com/mystic-grove.jpg")!),
                StageDTO(name: "Bass Haven", color: "#FF5733", imageURL: URL(string: "http://example.com/bass-haven.jpg")!),
                StageDTO(name: "Tranquil Meadow", color: "#4287f5", imageURL: nil)
            ]
        )
    }

    func testDecodingSimpleContactInfo() throws {
        let yaml = """
        - phoneNumber: "+1234567890"
          title: "General Info"

        - phoneNumber: "+0987654321"
          title: "Emergency"
          description: "For emergencies only"
        """

        let parser = Parsers.Yaml<[ContactInfoDTO]>()
        let dto = try parser.parse(yaml)

        #expect(
            dto ==
            [
                ContactInfoDTO(phoneNumber: "+1234567890", title: "General Info", description: nil),
                ContactInfoDTO(phoneNumber: "+0987654321", title: "Emergency", description: "For emergencies only")
            ]
        )
    }


    func testDecodingSimpleSchedule() throws {
        let yaml = """
        Bass Haven:
          - time: "10:00 PM"
            artist: "Prism Sound"

          - time: "11:30 PM"
            title: "Subsonic B2B Sylvan"
            artists:
               - "Subsonic"
               - "Sylvan Beats"

          - time: "12:30 AM"
            endTime: "2:00 AM"
            artist: "Space Chunk"

        Mystic Grove:
          - time: "4:30 PM"
            artist: "Sunspear"

          - time: "6:30 PM"
            artist: "Phantom Groove"

          - time: "10:30 PM"
            artist: "Oaktrail"

          - time: "12:00 AM"
            endTime: "4:00 AM"
            artist: "Rhythmbox"

        Tranquil Meadow:
          - time: "3:00 PM"
            artist: "Float On"

          - time: "4:30 PM"
            artist: "Floods"

          - time: "04:00 PM"
            endTime: "6:00 PM"
            artist: "Overgrowth"

          - time: "1:00 AM"
            endTime: "2:00 AM"
            artist: "The Sleepies"
            title: "The Wind Down"
        """

        let parser = Parsers.Yaml<EventDTO.DaySchedule>()
        let dto = try parser.parse(yaml)

        #expect(dto == .init(performances: [
            "Bass Haven": [
                PerformanceDTO(title: nil, artist: "Prism Sound", artists: nil, time: "10:00 PM"),
                PerformanceDTO(title: "Subsonic B2B Sylvan", artist: nil, artists: ["Subsonic", "Sylvan Beats"], time: "11:30 PM"),
                PerformanceDTO(title: nil, artist: "Space Chunk", artists: nil, time: "12:30 AM", endTime: "2:00 AM")
            ],
            "Mystic Grove": [
                PerformanceDTO(title: nil, artist: "Sunspear", artists: nil, time: "4:30 PM"),
                PerformanceDTO(title: nil, artist: "Phantom Groove", artists: nil, time: "6:30 PM"),
                PerformanceDTO(title: nil, artist: "Oaktrail", artists: nil, time: "10:30 PM"),
                PerformanceDTO(title: nil, artist: "Rhythmbox", artists: nil, time: "12:00 AM", endTime: "4:00 AM")
            ],
            "Tranquil Meadow": [
                PerformanceDTO(title: nil, artist: "Float On", artists: nil, time: "3:00 PM"),
                PerformanceDTO(title: nil, artist: "Floods", artists: nil, time: "4:30 PM"),
                PerformanceDTO(title: nil, artist: "Overgrowth", artists: nil, time: "04:00 PM", endTime: "6:00 PM"),
                PerformanceDTO(title: "The Wind Down", artist: "The Sleepies", artists: nil, time: "1:00 AM", endTime: "2:00 AM")
            ]
        ]))
    }


    func testDecodingSimpleArtist() throws {
        let yaml = """
            imageURL: http://example.com/subsonic.jpg
            links:
            - url: http://soundcloud.com/subsonic
            - url: http://instagram.com/subsonic
        """

        let parser = Parsers.Yaml<ArtistInfoFrontMatter>()

        let dto = try parser.parse(yaml)


        #expect(
            dto ==
            ArtistInfoFrontMatter(
                imageURL: .init(string: "http://example.com/subsonic.jpg"),
                links: [
                    .init(url: URL(string: "http://soundcloud.com/subsonic")!),
                    .init(url: URL(string: "http://instagram.com/subsonic")!)
                ]
            )
        )
    }
}

struct ArtistDecodingTests {
    @Test(.tags(.frontmatter))
    func decodingStandardArtistFile() throws {
        let markdown = """
        ---
        imageURL: http://example.com/subsonic.jpg
        links:
        - url: http://soundcloud.com/subsonic
        - url: http://instagram.com/subsonic
        ---
        Subsonic delivers powerful bass-driven music that shakes the ground and moves the crowd, known for their high-energy performances and deep, resonant beats.
        """

        var text = Substring(markdown)
        let parser = MarkdownWithFrontMatter<ArtistInfoFrontMatter>.Parser()
        let dto = try parser.parse(&text)

        #expect(
            dto == MarkdownWithFrontMatter(
                frontMatter: ArtistInfoFrontMatter(
                    imageURL: .init(string: "http://example.com/subsonic.jpg"),
                    links: [
                        .init(url: URL(string: "http://soundcloud.com/subsonic")!),
                        .init(url: URL(string: "http://instagram.com/subsonic")!)
                    ]
                ),
                body: "Subsonic delivers powerful bass-driven music that shakes the ground and moves the crowd, known for their high-energy performances and deep, resonant beats."
            )
        )

        try parser.print(dto, into: &text)
        #expect(Substring(markdown) == text)
    }

    @Test(.tags(.frontmatter))
    func decodingArtistFileWithNoFrontmatterRoundtripping() throws {
        let markdown = """
        Subsonic delivers powerful bass-driven music that shakes the ground and moves the crowd, known for their high-energy performances and deep, resonant beats.
        """

        var text = Substring(markdown)
        let parser = MarkdownWithFrontMatter<ArtistInfoFrontMatter>.Parser()
        let dto = try parser.parse(&text)

        #expect(
            dto == MarkdownWithFrontMatter(
                frontMatter: nil,
                body: "Subsonic delivers powerful bass-driven music that shakes the ground and moves the crowd, known for their high-energy performances and deep, resonant beats."
            )
        )

        try parser.print(dto, into: &text)
        #expect(markdown == text)
    }
}

