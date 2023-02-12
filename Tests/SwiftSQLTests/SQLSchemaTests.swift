//
//  SQLSchemaTests.swift
//  
//
//  Created by Jason Jobe on 1/30/23.
//

import XCTest
import SwiftSQL
import SwiftSQLExt
import KeyValueCoding
import SnapshotTesting


protocol Entity {}

final class SQLSchemaTests: XCTestCase {

    override func setUpWithError() throws {
        // Set `isRecording` to reset Snapshots
//        isRecording = true
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func sampleDatabase() throws -> SQLConnection {
        let db = try! SQLConnection(location: .memory())
        try db.execute("CREATE TABLE Test (name TEXT, ndx INT)")
        
        // WHEN/THEN binds the value
        try db.prepare("INSERT INTO Test (name, ndx) VALUES (?, ?)")
            .bind("alpha", 1)
            .execute()
        return db
    }
    
    func testInstantiateStrict() throws {
        // We delibertly do NOT select all columns
        // So it should raise an exception
        let db = try sampleDatabase()
        let statement = try db.prepare("SELECT name FROM Test")
        XCTAssertTrue(try statement.step())
        struct S: ExpressibleByDefault {
            var name: String
            var ndx: Int
            
            init(defaultContext: ()) {
                name = ""
                ndx = 0
            }
        }
        let s = Schema(for: S.self)
        do {
            let v: S = try s.instantiate(from: statement, strict: true)
            print (v)
        } catch {
            print(error.localizedDescription)
        }
//        assertSnapshot(matching: v, as: .dump)
    }

    func testInstantiateLoose() throws {
        // We delibertly do NOT select all columns
        // So some default values should remain
        let db = try sampleDatabase()
        let statement = try db.prepare("SELECT name FROM Test")
        XCTAssertTrue(try statement.step())
        struct S: ExpressibleByDefault {
            var name: String
            var ndx: Int
            
            init(defaultContext: ()) {
                name = ""
                ndx = 0
            }
        }
        let s = Schema(for: S.self)
        let v: S = try s.instantiate(from: statement, strict: false)
        assertSnapshot(matching: v, as: .dump)
    }
    
    func testInstantiate() throws {
        let db = try sampleDatabase()
         let statement = try db.prepare("SELECT name, ndx FROM Test")
        XCTAssertTrue(try statement.step())
        struct S: ExpressibleByDefault {
            var name: String
            var ndx: Int
            
            init(defaultContext: ()) {
                name = ""
                ndx = 0
            }
        }
        let s = Schema(for: S.self)
        let v: S = try s.instantiate(from: statement)
        assertSnapshot(matching: v, as: .dump)
    }

    func testTopic() throws {
        let db = try! SQLConnection(location: .memory())
        let s = Schema(for: Topic.self)

        let sql = s.sql(create: "topic")
        print(sql)
        try db.execute(sql)

        let insert = try db.prepare(s.sql(insert: "topic"))
        
            try insert
                .bind(1, "alpha", 23)
                .execute()

        let select = try db.prepare(s.sql(select: "topic"))

        while try select.step() {
            let t: Topic = try s.instantiate(from: select, strict: false)
            print (t)
        }
        
        let t1  = Topic(id: "10", name: "beta")
        try insert
            .reset()
            .bind(t1)
            .execute()

        let t2  = Topic(id: "20", name: "charlie")
        try insert
            .reset()
            .bind(t2)
            .execute()

        try select.reset()
        var results = [Any]()
        
        while try select.step() {
            let t: Topic = try s.instantiate(from: select, strict: false)
            results.append(t)
            print (t)
        }
                
        assertSnapshot(matching: results, as: .dump)
     }
    
    func testSchemaSQLCreate() throws {
        let s = Schema(for: Person.self)
        assertSnapshot(matching: s.sql(create: "person"), as: .lines)
    }
    
    func testSchemaSQLSelect() throws {
        let s = Schema(for: Person.self)
        assertSnapshot(matching: s.sql(select: "person"), as: .lines)
    }

    func testSchemaSQLInsert() throws {
        let s = Schema(for: Person.self)
        assertSnapshot(matching: s.sql(insert: "person"), as: .lines)
    }

}

//extension UUID {
//    static func preview(_ ndx: Int) -> UUID {
//        return .init(uuidString: "\ndx")!
//    }
//}
//            let v = _swift_getKeyPath(pattern: , arguments: )

struct TopicQuery: EntityQuery {
    func entities(for identifiers: [Topic.ID]) async throws -> [Topic] {
        .init()
    }
}

/*
 func suggestedEntities() async throws -> [AlbumEntity] {
 try await MusicCatalog.shared.favoriteAlbums()
 .map { AlbumEntity(id: $0.id, albumName: $0.name) }
 }
 
 */
import AppIntents

@available(macOS 13.0, *)
struct Topic: AppEntity {
    typealias ID = String
    static var defaultQuery: TopicQuery = .init()
    
    var id: ID
    var name: String
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Topic"
    }
    
    var displayRepresentation: DisplayRepresentation {
        .init(title: LocalizedStringResource(stringLiteral: name))
    }
    
}

//struct Topic {
//    var id: Int64
//    var name: String
//    var value: Int?
//}

extension Topic: ExpressibleByDefault {
    init(defaultContext: ()) {
        id = .init()
        name = ""
//        value = nil
    }
}

struct Person {
    var id: Int64
    var name: String
    var date: Date
    var dob: Date?
    var tags: [String]
    var friends: [Person]
}

extension Person: ExpressibleByDefault {
    init(defaultContext: ()) {
        self = .init(id: 0, name: "", date: .distantPast, tags: [], friends: [])
    }
}
