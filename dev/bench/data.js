window.BENCHMARK_DATA = {
  "lastUpdate": 1781725519593,
  "repoUrl": "https://github.com/ClaraY05/jsip-exchange",
  "entries": {
    "Order book benchmark": [
      {
        "commit": {
          "author": {
            "email": "cy2005024@gmail.com",
            "name": "Clara Yee",
            "username": "ClaraY05"
          },
          "committer": {
            "email": "cy2005024@gmail.com",
            "name": "Clara Yee",
            "username": "ClaraY05"
          },
          "distinct": true,
          "id": "9dc84af78bfbb4dfca773ae582b765244ddd3bf3",
          "message": "feat: completed and tested more aggressive and marketable features",
          "timestamp": "2026-06-17T19:36:52Z",
          "tree_id": "a047396279ec98b4c6cdaa5360ae6f018f780ec8",
          "url": "https://github.com/ClaraY05/jsip-exchange/commit/9dc84af78bfbb4dfca773ae582b765244ddd3bf3"
        },
        "date": 1781725518949,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "find_match (n=10)",
            "value": 21.78895181914503,
            "unit": "ns"
          },
          {
            "name": "find_match (n=50)",
            "value": 23.373887172890917,
            "unit": "ns"
          },
          {
            "name": "find_match (n=100)",
            "value": 22.522552345478747,
            "unit": "ns"
          },
          {
            "name": "find_match (n=500)",
            "value": 22.59506450968915,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=10)",
            "value": 106.4531502743437,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=50)",
            "value": 474.61712228497413,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=100)",
            "value": 925.1768690061093,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=500)",
            "value": 4576.838534961031,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=10)",
            "value": 213.50562466964922,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=50)",
            "value": 1010.8201165350837,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=100)",
            "value": 1960.3836623600505,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=500)",
            "value": 9689.717812478013,
            "unit": "ns"
          },
          {
            "name": "add+remove (n=100)",
            "value": 1395.6355362882834,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=10)",
            "value": 1156.257763293351,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=50)",
            "value": 4881.693711082947,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=100)",
            "value": 9424.265872718152,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=500)",
            "value": 45051.892027931724,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=10)",
            "value": 594.2232758449204,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=50)",
            "value": 2563.8735286967812,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=100)",
            "value": 4998.940681124592,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=500)",
            "value": 24140.566363091697,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_10_levels",
            "value": 4973.517886971721,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_50_levels",
            "value": 77976.29911182221,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_100_levels",
            "value": 283511.4403291023,
            "unit": "ns"
          },
          {
            "name": "find_match_alloc (n=100)",
            "value": 22.56675064444219,
            "unit": "ns"
          }
        ]
      }
    ]
  }
}