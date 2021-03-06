//
//  AssetsCollectionDataSource.h
//  ThumbnailServiceDemo
//
//  Created by Aleksey Garbarev on 10.10.13.
//  Copyright (c) 2013 Aleksey Garbarev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PreviewDataSource.h"

@interface AssetsCollectionDataSource : NSObject <UICollectionViewDataSource, UICollectionViewDelegate, PreviewDataSource>

@property (nonatomic, weak) UICollectionView *collectionView;

@end
