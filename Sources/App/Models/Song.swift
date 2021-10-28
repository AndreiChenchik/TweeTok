//
//  Song.swift
//  
//
//  Created by Andrei Chenchik on 28/10/21.
//

import Fluent
import Vapor

final class Song: Model, Content {
    static let schema = "songs"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "title")
    var title: String

    init() { }

    init(id: UUID? = nil, title: String) {
        self.id = id
        self.title = title
    }
}
