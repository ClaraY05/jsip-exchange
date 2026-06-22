window.BENCHMARK_DATA = {
  "lastUpdate": 1782133825268,
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
      },
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
          "id": "f9bb4b381f6a20c58254648075b0e7a7d0f7dc48",
          "message": "fix: patched improper equality in snapshot side",
          "timestamp": "2026-06-18T20:50:13Z",
          "tree_id": "09fc3a37b6214e7801e9ba98368a134d439d4345",
          "url": "https://github.com/ClaraY05/jsip-exchange/commit/f9bb4b381f6a20c58254648075b0e7a7d0f7dc48"
        },
        "date": 1781816137566,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "find_match (n=10)",
            "value": 237.77831448549398,
            "unit": "ns"
          },
          {
            "name": "find_match (n=50)",
            "value": 1192.546183310347,
            "unit": "ns"
          },
          {
            "name": "find_match (n=100)",
            "value": 2335.0621532157998,
            "unit": "ns"
          },
          {
            "name": "find_match (n=500)",
            "value": 11770.814053036853,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=10)",
            "value": 117.76857663484334,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=50)",
            "value": 533.6134531498793,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=100)",
            "value": 1043.9721323747776,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=500)",
            "value": 5002.0861906853925,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=10)",
            "value": 249.8243804315829,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=50)",
            "value": 1191.8285331719171,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=100)",
            "value": 2310.5263276019477,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=500)",
            "value": 11511.484295052476,
            "unit": "ns"
          },
          {
            "name": "add+remove (n=100)",
            "value": 1472.312631095213,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=10)",
            "value": 1586.9981668506914,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=50)",
            "value": 6809.7235208421735,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=100)",
            "value": 13287.137695186824,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=500)",
            "value": 66656.55953528853,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=10)",
            "value": 696.9922944986464,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=50)",
            "value": 3213.0035577012504,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=100)",
            "value": 6093.128469640744,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=500)",
            "value": 29465.894302383767,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_10_levels",
            "value": 6686.961784728512,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_50_levels",
            "value": 117723.63026481829,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_100_levels",
            "value": 449237.22679801594,
            "unit": "ns"
          },
          {
            "name": "find_match_alloc (n=100)",
            "value": 2329.154255918159,
            "unit": "ns"
          }
        ]
      },
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
          "id": "a97353e597ade28e95cff1eddf982fca04782871",
          "message": "feat: added initial files for exchange command implementations",
          "timestamp": "2026-06-22T13:05:58Z",
          "tree_id": "d94cbe614a7d6ad073f4c261962d97a76d0f7989",
          "url": "https://github.com/ClaraY05/jsip-exchange/commit/a97353e597ade28e95cff1eddf982fca04782871"
        },
        "date": 1782133819788,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "find_match (n=10)",
            "value": 270.11794445354445,
            "unit": "ns"
          },
          {
            "name": "find_match (n=50)",
            "value": 1298.431954710344,
            "unit": "ns"
          },
          {
            "name": "find_match (n=100)",
            "value": 2604.950220329721,
            "unit": "ns"
          },
          {
            "name": "find_match (n=500)",
            "value": 13122.723709469912,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=10)",
            "value": 117.05208078289766,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=50)",
            "value": 511.2490358332921,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=100)",
            "value": 1000.4310447041267,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=500)",
            "value": 5207.839329584106,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=10)",
            "value": 279.3196218020175,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=50)",
            "value": 1298.2249594076798,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=100)",
            "value": 2712.1698130777227,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=500)",
            "value": 13490.452581197038,
            "unit": "ns"
          },
          {
            "name": "add+remove (n=100)",
            "value": 1697.45569860476,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=10)",
            "value": 1812.9511541177044,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=50)",
            "value": 7771.168102864573,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=100)",
            "value": 15342.024102755018,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=500)",
            "value": 74303.2728843343,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=10)",
            "value": 781.5763579494271,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=50)",
            "value": 3441.615297918316,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=100)",
            "value": 6810.368866108424,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=500)",
            "value": 33930.3167132102,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_10_levels",
            "value": 7741.005521354951,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_50_levels",
            "value": 130004.59434565439,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_100_levels",
            "value": 499601.4414627729,
            "unit": "ns"
          },
          {
            "name": "find_match_alloc (n=100)",
            "value": 2734.310323829788,
            "unit": "ns"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "77038444+ClaraY05@users.noreply.github.com",
            "name": "ClaraY05",
            "username": "ClaraY05"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "67b0962c1a316e79583d219e2ba172fc602487e3",
          "message": "Merge branch 'jane-street-immersion-program:main' into main",
          "timestamp": "2026-06-22T09:06:35-04:00",
          "tree_id": "ef078a2f66213c78a8dd3ad235f7e33a08cc46da",
          "url": "https://github.com/ClaraY05/jsip-exchange/commit/67b0962c1a316e79583d219e2ba172fc602487e3"
        },
        "date": 1782133824936,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "find_match (n=10)",
            "value": 253.39994227321236,
            "unit": "ns"
          },
          {
            "name": "find_match (n=50)",
            "value": 1259.7421301569236,
            "unit": "ns"
          },
          {
            "name": "find_match (n=100)",
            "value": 2433.363556583586,
            "unit": "ns"
          },
          {
            "name": "find_match (n=500)",
            "value": 12333.920489515227,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=10)",
            "value": 118.56604579572338,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=50)",
            "value": 534.1993451848574,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=100)",
            "value": 1047.4169668060697,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=500)",
            "value": 5230.484606543311,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=10)",
            "value": 247.00991087688723,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=50)",
            "value": 1150.0604949947603,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=100)",
            "value": 2296.415701102556,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=500)",
            "value": 11216.001338813256,
            "unit": "ns"
          },
          {
            "name": "add+remove (n=100)",
            "value": 1507.6570455616916,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=10)",
            "value": 1626.0548258166104,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=50)",
            "value": 7145.163852198703,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=100)",
            "value": 13581.029578196985,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=500)",
            "value": 67764.3795653574,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=10)",
            "value": 723.7609170477322,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=50)",
            "value": 3137.5411919456824,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=100)",
            "value": 6042.468984485833,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=500)",
            "value": 29297.273930042677,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_10_levels",
            "value": 6823.527703831314,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_50_levels",
            "value": 120902.32839251477,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_100_levels",
            "value": 455258.7044881708,
            "unit": "ns"
          },
          {
            "name": "find_match_alloc (n=100)",
            "value": 2375.9730417258647,
            "unit": "ns"
          }
        ]
      }
    ]
  }
}