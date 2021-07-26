//
//  RichLinkSpecializationFormat.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/13/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import LinkPresentation

enum RichLinkSpecializationFormat: String, Codable {
    case podcastEpisode
    case familyInvitation
    case movieBundle
    case software
    case file
    case playlist
    case artist
    case icloudSharing
    case map
    case tvEpisode
    case news
    case radio
    case movie
    case tvShow
    case album
    case tvSeason
    case podcast
    case businessChat
    case appleTV
    case song
    case mapCollection
    case audioBook
    case musicVideo
    case summarizedLink
    case walletPass
    case appStoreStory
    case book
    case gameCenterInvitation
    case applePhotosStatus
    case applePhotosMoment
    
    init?(_ specialization: LPSpecializationMetadata) {
        switch specialization {
        case is LPiTunesMediaPodcastEpisodeMetadata:
            self = .podcastEpisode
        case is LPiCloudFamilyInvitationMetadata:
            self = .familyInvitation
        case is LPiTunesMediaMovieBundleMetadata:
            self = .movieBundle
        case is LPiTunesMediaSoftwareMetadata:
            self = .software
        case is LPFileMetadata:
            self = .file
        case is LPiTunesMediaPlaylistMetadata:
            self = .playlist
        case is LPiTunesMediaArtistMetadata:
            self = .artist
        case is LPiCloudSharingMetadata:
            self = .icloudSharing
        case is LPMapMetadata:
            self = .map
        case is LPiTunesMediaTVEpisodeMetadata:
            self = .tvEpisode
        case is LPAppleNewsMetadata:
            self = .news
        case is LPiTunesMediaRadioMetadata:
            self = .radio
        case is LPiTunesMediaMovieMetadata:
            self = .movie
        case is LPAppleMusicTVShowMetadata:
            self = .tvShow
        case is LPiTunesMediaAlbumMetadata:
            self = .album
        case is LPiTunesMediaTVSeasonMetadata:
            self = .tvSeason
        case is LPiTunesMediaPodcastMetadata:
            self = .podcast
        case is LPBusinessChatMetadata:
            self = .businessChat
        case is LPAppleTVMetadata:
            self = .appleTV
        case is LPiTunesMediaSongMetadata:
            self = .song
        case is LPMapCollectionMetadata:
            self = .mapCollection
        case is LPiTunesMediaAudioBookMetadata:
            self = .audioBook
        case is LPiTunesMediaMusicVideoMetadata:
            self = .musicVideo
        case is LPSummarizedLinkMetadata:
            self = .summarizedLink
        case is LPWalletPassMetadata:
            self = .walletPass
        case is LPAppStoreStoryMetadata:
            self = .appStoreStory
        case is LPiTunesMediaBookMetadata:
            self = .book
        case is LPGameCenterInvitationMetadata:
            self = .gameCenterInvitation
        case is LPApplePhotosStatusMetadata:
            self = .applePhotosStatus
        case is LPApplePhotosMomentMetadata:
            self = .applePhotosMoment
        default:
            return nil
        }
    }
}

internal extension LPSpecializationMetadata {
    var format: RichLinkSpecializationFormat? {
        RichLinkSpecializationFormat(self)
    }
}
