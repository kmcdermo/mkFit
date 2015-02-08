#ifndef _event_
#define _event_

#include "Track.h"
#include "Validation.h"
#include "Geometry.h"

typedef std::pair<unsigned int,unsigned int> BinInfo;

class Event {
public:
  Event(Geometry& g, Validation& v);
  void Simulate(unsigned int nTracks);
  void Segment();
  void Seed();
  void Find();
  void Fit();

  Geometry& geom_;
  Validation& validation_;
  std::vector<HitVec> layerHits_;
  TrackVec simTracks_, seedTracks_, candidateTracks_;

  //these matrices are dummy and can be optimized without multiplying by zero all the world...
  SMatrix36 projMatrix36_;
  SMatrix63 projMatrix36T_;

  // phi-eta partitioning map: vector of vector of vectors of std::pairs. 
  // vec[nLayers][nEtaBins][nPhiBins]
  std::vector<std::vector<std::vector<BinInfo> > > lay_eta_phi_hit_idx_;

};

typedef std::vector<Event> EventVec;

#endif
