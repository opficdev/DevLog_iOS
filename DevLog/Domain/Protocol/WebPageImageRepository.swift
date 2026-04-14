//
//  WebPageImageRepository.swift
//  DevLog
//
//  Created by opfic on 4/14/26.
//

protocol WebPageImageRepository {
    func fetchDirSizeInBytes() -> Int64
    func clearDirectory() throws
}
