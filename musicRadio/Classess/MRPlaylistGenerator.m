//
//  MRPlaylistGenerator.m
//  musicRadio
//
//  Created by Takuya Okamoto on 2014/01/30.
//  Copyright (c) 2014年 Takuya Okamoto. All rights reserved.
//

#import "MRPlaylistGenerator.h"
#import "MRLastfmRequest.h"
#import "MRRadio.h"

#define MAX_PLAYLIST_LENGTH 500

@implementation MRPlaylistGenerator {
    MRLastfmRequest *_lastfmRequest;
    NSMutableArray *_playList;
}



- (id) init
{
    NSLog(@"init of MRPlaylistGenerator.");
    self = [super init];
    
    if (self != nil) {
        //ここにサブクラス固有の初期化をかく
        _lastfmRequest = [[MRLastfmRequest alloc] init];
        _playList = [NSMutableArray array];
    }
    return self;
}



// --------------- public method ------------------

-(int) generatePlaylistByArtistName: (NSString*)artistName callback:(id)callback{

    NSLog(@"generatePlaylistByArtistName");

    BOOL is_playing = NO;
    NSArray *topTracks = [_lastfmRequest getTopTracksWithArtistName:artistName];
    int topTrackLength = (int)[topTracks count];
    NSLog(@"toptracks count: %d", topTrackLength);
    
    
    //ここでループしてプレイリスト作成する。
    int i, j;
    for (i=0; i<topTrackLength; i++) {
        
        if( [_playList count] >= MAX_PLAYLIST_LENGTH ) break;
        
        NSDictionary *track = topTracks[i];
        
        NSLog(@"toptracks %d: %@=========================", i, topTracks[i][@"name"]);
        
        NSArray *similarTracks = [_lastfmRequest getSimilarTracksWithMbid:track[@"mbid"]];
        
        if (similarTracks) {
            int similarTracksLength = (int)[similarTracks count];
            NSLog(@"similarTrack is exist!   length: %d", similarTracksLength);
            
            for (j=0; j<similarTracksLength; j++) {
                NSDictionary *addTrack = similarTracks[j];
//                NSLog(@"addTrack %d: %@",j, addTrack[@"name"]);
                
                //画像がない場合は "nothing"
                NSString *trackImage = @"nothing";
                BOOL is_image_exist = [addTrack.allKeys containsObject:@"image"];
                if (is_image_exist) trackImage = addTrack[@"image"][3];
                
                NSDictionary *addDict = @{@"name"   : addTrack[@"name"],
                                           @"artist" : addTrack[@"artist"][@"name"],
                                           @"image"  : trackImage,
                                           @"mbid"   : addTrack[@"mbid"]};

                [_playList addObject:addDict];
                
                //プレイリストがMAX超えたらトラック追加をやめる。
                if([_playList count] >= MAX_PLAYLIST_LENGTH) {
                    NSLog(@"playlist count is over!");
                    break;
                }
            }
            
            //ここでまだ再生してなかったらもう再生始める。 マルチスレッド処理にする？
            if (!is_playing){
                is_playing = YES;
                [callback onCreatedPlaylist];
            }
        }
        else {
            NSLog(@"similar tracks is not exist!!");
            break;//ここで似てるアーティストに変更
        }
    }
    
    NSLog(@"playlist is all created.  playlist length: %d",(int)[_playList count]);
    
    return 0;
}





-(NSDictionary*)getRandomTrack {
    int randIndex = (int)arc4random_uniform( (int)[_playList count] );
    return [_playList objectAtIndex:randIndex];
}


-(int) resetPlaylist {
    [_playList removeAllObjects];
    return 0;
}




@end
