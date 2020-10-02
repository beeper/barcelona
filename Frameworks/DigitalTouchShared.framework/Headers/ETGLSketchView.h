//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import <Foundation/Foundation.h>

#import "ETGLSketchRendererDelegate.h"

@class ETBoxcarFilterPointFIFO, ETGLSketchRenderer, ETPointFIFO, ETQuadCurvePointFIFO, ETSketchMessage, NSColor, NSOpenGLContext;

@interface ETGLSketchView : NSObject <ETGLSketchRendererDelegate>
{
    NSColor *_currentStrokeColor;
    double _lastDisplayLinkTime;
    BOOL _renderingOffscreen;
    unsigned long long _currentStrokeIndex;
    unsigned long long _currentPointIndex;
    unsigned long long _numberOfDrawnStrokes;
    double _renderingDelay;
    double _renderingStartTime;
    double _pauseTime;
    BOOL _playing;
    BOOL _paused;
    BOOL _playbackCompleted;
    BOOL _useFastVerticalWisp;
    float _unitSize;
    ETSketchMessage *_messageData;
    double _wispDelay;
    double _timestampForLastDrawnPoint;
    NSOpenGLContext *_context;
    ETGLSketchRenderer *_renderer;
    ETQuadCurvePointFIFO *_interpolatingFIFO;
    ETBoxcarFilterPointFIFO *_smoothingFIFO;
    ETPointFIFO *_pointFIFO;
    ETQuadCurvePointFIFO *_secondaryInterpolatingFIFO;
    ETBoxcarFilterPointFIFO *_secondarySmoothingFIFO;
    ETPointFIFO *_secondaryPointFIFO;
    unsigned long long _vertexOffset;
    double _delayBetweenStrokes;
    id _vertexBatches;
    id _controlBatches;
    id _vertexBatchCount;
    id _secondaryVertexBatchCount;
}

+ (Class)layerClass;


@property(nonatomic) double delayBetweenStrokes; // @synthesize delayBetweenStrokes=_delayBetweenStrokes;
@property(nonatomic) unsigned long long vertexOffset; // @synthesize vertexOffset=_vertexOffset;
@property(nonatomic) id secondaryVertexBatchCount; // @synthesize secondaryVertexBatchCount=_secondaryVertexBatchCount;
@property(nonatomic) id vertexBatchCount; // @synthesize vertexBatchCount=_vertexBatchCount;
@property(nonatomic) id controlBatches; // @synthesize controlBatches=_controlBatches;
@property(nonatomic) id vertexBatches; // @synthesize vertexBatches=_vertexBatches;
@property(nonatomic) float unitSize; // @synthesize unitSize=_unitSize;
@property(retain, nonatomic) ETPointFIFO *secondaryPointFIFO; // @synthesize secondaryPointFIFO=_secondaryPointFIFO;
@property(retain, nonatomic) ETBoxcarFilterPointFIFO *secondarySmoothingFIFO; // @synthesize secondarySmoothingFIFO=_secondarySmoothingFIFO;
@property(retain, nonatomic) ETQuadCurvePointFIFO *secondaryInterpolatingFIFO; // @synthesize secondaryInterpolatingFIFO=_secondaryInterpolatingFIFO;
@property(retain, nonatomic) ETPointFIFO *pointFIFO; // @synthesize pointFIFO=_pointFIFO;
@property(retain, nonatomic) ETBoxcarFilterPointFIFO *smoothingFIFO; // @synthesize smoothingFIFO=_smoothingFIFO;
@property(retain, nonatomic) ETQuadCurvePointFIFO *interpolatingFIFO; // @synthesize interpolatingFIFO=_interpolatingFIFO;
@property(retain, nonatomic) ETGLSketchRenderer *renderer; // @synthesize renderer=_renderer;
@property(retain, nonatomic) NSOpenGLContext *context; // @synthesize context=_context;
@property(nonatomic) BOOL useFastVerticalWisp; // @synthesize useFastVerticalWisp=_useFastVerticalWisp;
@property(nonatomic) BOOL playbackCompleted; // @synthesize playbackCompleted=_playbackCompleted;
@property(nonatomic) double timestampForLastDrawnPoint; // @synthesize timestampForLastDrawnPoint=_timestampForLastDrawnPoint;
@property(nonatomic) double wispDelay; // @synthesize wispDelay=_wispDelay;
@property(nonatomic, getter=isPaused) BOOL paused; // @synthesize paused=_paused;
@property(nonatomic, getter=isPlaying) BOOL playing; // @synthesize playing=_playing;
@property(retain, nonatomic) ETSketchMessage *messageData; // @synthesize messageData=_messageData;
- (void)sketchRendererDidReachVertexLimit:(id)arg1;
- (void)clearAllPoints;
- (void)didCompleteStroke;
- (void)handleSketchAtPosition:(struct CGPoint)arg1;


- (void)handleTapAtPosition:(struct CGPoint)arg1;
- (void)updateScaleFactorForSize:(struct CGSize)arg1;
- (void)clear;
- (void)_endPlayback;
- (struct CGImage *)createImageForTime:(double)arg1;
- (struct CGImage *)createRenderedFrameImage;
- (BOOL)_getCurrentSketchPoint:(id)arg1;
- (BOOL)_doesPoint:(id)arg1 predateTime:(double)arg2;
- (void)drawFrameBeforeWisp;
- (void)_drawCurrentPointAdvancingPlayback;
- (void)sampleIntoDestination:(struct CGImageDestination *)arg1 frameProperties:(struct __CFDictionary *)arg2 usingAlpha:(BOOL)arg3;
- (void)beginStrokeWithColor:(id)arg1;
- (void)animateOutWithCompletion:(id)arg1;
- (id)initWithFrame:(struct CGRect)arg1;
- (void)setGLContextAsCurrent;

@end
