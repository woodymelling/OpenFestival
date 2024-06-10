import Testing
import Foundation
@testable import OpenFestivalParser
import Yams
import CustomDump
import OpenFestivalModels

@Suite("YamlDecoding")
struct YamlDecodingTests {
    @Test
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
        
        let encoder = YAMLDecoder()
        
        let dto = try encoder.decode(EventInfoDTO.self, from: yaml)

        #expect(
            dto == EventInfoDTO(
                name: "Testival",
                address: "123 Festival Road, Music City",
                timeZone: "America/Seattle",
                imageURL: URL(string: "http://example.com/event-image.jpg"),
                siteMapImageURL: URL(string: "http://example.com/site-map.jpg"),
                colorScheme: .init(primaryColor: "#FF5733", workshopsColor: "#C70039")
            )
        )
    }

    @Test
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
        
        let encoder = YAMLDecoder()
        
        let dto = try encoder.decode([StageDTO].self, from: yaml)

        #expect(
            dto == [
                StageDTO(name: "Mystic Grove", color: "#1DB954", imageURL: URL(string: "http://example.com/mystic-grove.jpg")!),
                StageDTO(name: "Bass Haven", color: "#FF5733", imageURL: URL(string: "http://example.com/bass-haven.jpg")!),
                StageDTO(name: "Tranquil Meadow", color: "#4287f5", imageURL: nil)
            ]
        )
    }

    @Test
    func testDecodingSimpleContactInfo() throws {
        let yaml = """
        - phoneNumber: "+1234567890" 
          title: "General Info" 
          
        - phoneNumber: "+0987654321" 
          title: "Emergency" 
          description: "For emergencies only"
        """
        
        let encoder = YAMLDecoder()
        
        let dto = try encoder.decode([ContactInfoDTO].self, from: yaml)

        #expect(
            dto == [
                ContactInfoDTO(phoneNumber: "+1234567890", title: "General Info", description: nil),
                ContactInfoDTO(phoneNumber: "+0987654321", title: "Emergency", description: "For emergencies only")
            ]
        )
    }

    @Test
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

        let encoder = YAMLDecoder()
        let dto = try encoder.decode([String: [PerformanceDTO]].self, from: yaml)

        #expect(dto == [
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
        ])
    }
}
