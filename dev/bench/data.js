window.BENCHMARK_DATA = {
  "lastUpdate": 1782421233164,
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
          "id": "96f69e2f8e27b5eb54b72c3220d8cd56e5c4d7c6",
          "message": "feat: Completed and tested new implementation exchange_command",
          "timestamp": "2026-06-22T17:54:42Z",
          "tree_id": "2d6a81bd79c69bafddea14fe07667049f58b43d1",
          "url": "https://github.com/ClaraY05/jsip-exchange/commit/96f69e2f8e27b5eb54b72c3220d8cd56e5c4d7c6"
        },
        "date": 1782151126778,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "find_match (n=10)",
            "value": 261.37414919179224,
            "unit": "ns"
          },
          {
            "name": "find_match (n=50)",
            "value": 1290.2895573512535,
            "unit": "ns"
          },
          {
            "name": "find_match (n=100)",
            "value": 2554.3020854509637,
            "unit": "ns"
          },
          {
            "name": "find_match (n=500)",
            "value": 12375.291879775454,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=10)",
            "value": 111.67811759802235,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=50)",
            "value": 501.57996525795505,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=100)",
            "value": 984.8040748127002,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=500)",
            "value": 4852.584302834727,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=10)",
            "value": 240.17764606557293,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=50)",
            "value": 1211.0089253406645,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=100)",
            "value": 2406.651682852926,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=500)",
            "value": 11867.749545369765,
            "unit": "ns"
          },
          {
            "name": "add+remove (n=100)",
            "value": 1375.382507162655,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=10)",
            "value": 1638.6355522602087,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=50)",
            "value": 7209.023382509688,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=100)",
            "value": 14565.654776225365,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=500)",
            "value": 69815.13081051799,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=10)",
            "value": 703.8301553696895,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=50)",
            "value": 3183.4953657958868,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=100)",
            "value": 5964.483317338713,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=500)",
            "value": 29172.732033842287,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_10_levels",
            "value": 6937.580671553632,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_50_levels",
            "value": 123077.70149778342,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_100_levels",
            "value": 466132.57100943866,
            "unit": "ns"
          },
          {
            "name": "find_match_alloc (n=100)",
            "value": 2460.885322203024,
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
          "id": "63c87cc2d66c4499089a83e72620202e2e66ff42",
          "message": "refactor: moved parse calls from original protocol file, changed to event_formatter",
          "timestamp": "2026-06-22T18:33:01Z",
          "tree_id": "dc73bf62a41370263beafc8cec4e75a6d81ad496",
          "url": "https://github.com/ClaraY05/jsip-exchange/commit/63c87cc2d66c4499089a83e72620202e2e66ff42"
        },
        "date": 1782153429338,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "find_match (n=10)",
            "value": 238.91381819413255,
            "unit": "ns"
          },
          {
            "name": "find_match (n=50)",
            "value": 1235.379410367308,
            "unit": "ns"
          },
          {
            "name": "find_match (n=100)",
            "value": 2437.2154433576684,
            "unit": "ns"
          },
          {
            "name": "find_match (n=500)",
            "value": 12058.40096689982,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=10)",
            "value": 111.58618368294536,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=50)",
            "value": 502.13335176892946,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=100)",
            "value": 983.82783128498,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=500)",
            "value": 4847.317979979559,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=10)",
            "value": 259.8228990556668,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=50)",
            "value": 1221.0267478269068,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=100)",
            "value": 2433.10177241124,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=500)",
            "value": 12191.986569354227,
            "unit": "ns"
          },
          {
            "name": "add+remove (n=100)",
            "value": 1363.4735483370252,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=10)",
            "value": 1621.8756337784498,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=50)",
            "value": 7279.7880026220755,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=100)",
            "value": 13740.121764955831,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=500)",
            "value": 67871.56990304592,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=10)",
            "value": 691.9147584583948,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=50)",
            "value": 3131.361785621962,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=100)",
            "value": 6047.111530867129,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=500)",
            "value": 29919.724199672193,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_10_levels",
            "value": 6788.11287484496,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_50_levels",
            "value": 122665.2264724038,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_100_levels",
            "value": 457176.51673865505,
            "unit": "ns"
          },
          {
            "name": "find_match_alloc (n=100)",
            "value": 2450.4632598122457,
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
          "id": "7d41ff0d514948247064fd3a7eb3473e36e89559",
          "message": "refactor: cleaned up comments and formatting on exchange_command related files",
          "timestamp": "2026-06-22T18:46:30Z",
          "tree_id": "42d7116851e3c6ac2801a8c0c4b3fbea4c4a1b7d",
          "url": "https://github.com/ClaraY05/jsip-exchange/commit/7d41ff0d514948247064fd3a7eb3473e36e89559"
        },
        "date": 1782154233250,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "find_match (n=10)",
            "value": 274.96667875042294,
            "unit": "ns"
          },
          {
            "name": "find_match (n=50)",
            "value": 1213.003704680898,
            "unit": "ns"
          },
          {
            "name": "find_match (n=100)",
            "value": 2492.553797403936,
            "unit": "ns"
          },
          {
            "name": "find_match (n=500)",
            "value": 11832.670137125398,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=10)",
            "value": 117.48861304641254,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=50)",
            "value": 512.8795385418971,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=100)",
            "value": 1018.257088820083,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=500)",
            "value": 4814.799853201869,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=10)",
            "value": 270.33313881979814,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=50)",
            "value": 1234.1070250066446,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=100)",
            "value": 2469.087474868042,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=500)",
            "value": 12796.050221964026,
            "unit": "ns"
          },
          {
            "name": "add+remove (n=100)",
            "value": 1778.2986487419528,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=10)",
            "value": 1774.5942883262564,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=50)",
            "value": 7719.984933798762,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=100)",
            "value": 15671.780678460223,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=500)",
            "value": 75996.06993803509,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=10)",
            "value": 784.9640475841164,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=50)",
            "value": 3402.662451429115,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=100)",
            "value": 6654.951606800079,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=500)",
            "value": 33095.670043834754,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_10_levels",
            "value": 7639.830119285088,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_50_levels",
            "value": 129381.65574898403,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_100_levels",
            "value": 508136.29954595875,
            "unit": "ns"
          },
          {
            "name": "find_match_alloc (n=100)",
            "value": 2698.9659998802213,
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
          "id": "4b33a339bba9607dd6c03d284fdf5c5a80256294",
          "message": "feat: Added participant table and session handling in Dispatch",
          "timestamp": "2026-06-24T17:12:12Z",
          "tree_id": "dcb0ba4e51ffe6767c98571d621a82ce53145270",
          "url": "https://github.com/ClaraY05/jsip-exchange/commit/4b33a339bba9607dd6c03d284fdf5c5a80256294"
        },
        "date": 1782321372614,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "find_match (n=10)",
            "value": 136.69350807215744,
            "unit": "ns"
          },
          {
            "name": "find_match (n=50)",
            "value": 584.1834897075593,
            "unit": "ns"
          },
          {
            "name": "find_match (n=100)",
            "value": 1177.4108757103143,
            "unit": "ns"
          },
          {
            "name": "find_match (n=500)",
            "value": 5794.5774502541835,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=10)",
            "value": 137.65724769303432,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=50)",
            "value": 613.1624413242625,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=100)",
            "value": 1227.039292332415,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=500)",
            "value": 5970.871830052231,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=10)",
            "value": 131.07573883196554,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=50)",
            "value": 541.851552962915,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=100)",
            "value": 1067.12749136411,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=500)",
            "value": 5296.6710998406525,
            "unit": "ns"
          },
          {
            "name": "add+remove (n=100)",
            "value": 19286.928371855938,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=10)",
            "value": 2158.562664857326,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=50)",
            "value": 11215.049415229098,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=100)",
            "value": 24866.78553706148,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=500)",
            "value": 176262.98130407324,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=10)",
            "value": 513.5751836235588,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=50)",
            "value": 1902.2231512911217,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=100)",
            "value": 3681.937325498234,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=500)",
            "value": 17598.260554585704,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_10_levels",
            "value": 10189.27224357353,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_50_levels",
            "value": 250741.49988810692,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_100_levels",
            "value": 1102540.8196314864,
            "unit": "ns"
          },
          {
            "name": "find_match_alloc (n=100)",
            "value": 1130.092475481017,
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
          "id": "48c8630f1d2937497bcbaf4ca77f73b3e1842136",
          "message": "feat: completed implementation of login and login session state tracking in gateway",
          "timestamp": "2026-06-25T17:55:51Z",
          "tree_id": "a98cce66402bc824625e11c14c3b7db9ccfafae9",
          "url": "https://github.com/ClaraY05/jsip-exchange/commit/48c8630f1d2937497bcbaf4ca77f73b3e1842136"
        },
        "date": 1782410486213,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "find_match (n=10)",
            "value": 141.57389489202652,
            "unit": "ns"
          },
          {
            "name": "find_match (n=50)",
            "value": 636.6874982775414,
            "unit": "ns"
          },
          {
            "name": "find_match (n=100)",
            "value": 1277.8566147949236,
            "unit": "ns"
          },
          {
            "name": "find_match (n=500)",
            "value": 6305.746566015535,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=10)",
            "value": 136.28638701891484,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=50)",
            "value": 617.7481014036687,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=100)",
            "value": 1231.311664085294,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=500)",
            "value": 5970.194923478314,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=10)",
            "value": 134.46056450704506,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=50)",
            "value": 608.3861818621754,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=100)",
            "value": 1208.5663381770669,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=500)",
            "value": 5929.860016970538,
            "unit": "ns"
          },
          {
            "name": "add+remove (n=100)",
            "value": 6522.148341096876,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=10)",
            "value": 1536.162453051121,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=50)",
            "value": 6474.860342692803,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=100)",
            "value": 12081.219700911326,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=500)",
            "value": 79299.34412410721,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=10)",
            "value": 510.40646431946124,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=50)",
            "value": 1989.3705474676701,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=100)",
            "value": 3847.6032825231223,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=500)",
            "value": 18646.768202737047,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_10_levels",
            "value": 7346.6299522558365,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_50_levels",
            "value": 137613.59044086243,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_100_levels",
            "value": 532995.2348231078,
            "unit": "ns"
          },
          {
            "name": "find_match_alloc (n=100)",
            "value": 1320.098101444907,
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
          "id": "bac48e782ebb990872a0ddacf090579cd4149b4d",
          "message": "fix: Fixed variable allocation s.t. there is no longer multiple instances of values",
          "timestamp": "2026-06-25T20:13:06Z",
          "tree_id": "99f8ace16292f8fb47fdebadfc9d2df2c42d57e2",
          "url": "https://github.com/ClaraY05/jsip-exchange/commit/bac48e782ebb990872a0ddacf090579cd4149b4d"
        },
        "date": 1782419393649,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "find_match (n=10)",
            "value": 133.7271689927101,
            "unit": "ns"
          },
          {
            "name": "find_match (n=50)",
            "value": 597.405909238898,
            "unit": "ns"
          },
          {
            "name": "find_match (n=100)",
            "value": 1145.0765491674665,
            "unit": "ns"
          },
          {
            "name": "find_match (n=500)",
            "value": 5735.975179100369,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=10)",
            "value": 135.66078658807342,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=50)",
            "value": 613.1180486915804,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=100)",
            "value": 1226.8421248307861,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=500)",
            "value": 5935.62276390475,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=10)",
            "value": 134.4080087874813,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=50)",
            "value": 563.1501431383629,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=100)",
            "value": 1097.5774585037923,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=500)",
            "value": 5377.254918805115,
            "unit": "ns"
          },
          {
            "name": "add+remove (n=100)",
            "value": 6282.863742350282,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=10)",
            "value": 1514.9499212547175,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=50)",
            "value": 6203.237934774488,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=100)",
            "value": 12829.241660325371,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=500)",
            "value": 73260.471707134,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=10)",
            "value": 488.5887609492421,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=50)",
            "value": 1896.9198899367932,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=100)",
            "value": 3603.788676701821,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=500)",
            "value": 17511.388184105213,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_10_levels",
            "value": 7193.071032992436,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_50_levels",
            "value": 126648.59342627258,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_100_levels",
            "value": 493960.5001032116,
            "unit": "ns"
          },
          {
            "name": "find_match_alloc (n=100)",
            "value": 1161.9402148769045,
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
          "id": "cebfb4d74ac70442d8a2ebe33692e10366ac1a9d",
          "message": "fix: Fixed ordering of conditional in log in s.t. default is not an error",
          "timestamp": "2026-06-25T20:57:01Z",
          "tree_id": "a41f7420ec4594a53a7b904b853b1f88e95c23f3",
          "url": "https://github.com/ClaraY05/jsip-exchange/commit/cebfb4d74ac70442d8a2ebe33692e10366ac1a9d"
        },
        "date": 1782421232806,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "find_match (n=10)",
            "value": 133.52466609961238,
            "unit": "ns"
          },
          {
            "name": "find_match (n=50)",
            "value": 598.4050003410828,
            "unit": "ns"
          },
          {
            "name": "find_match (n=100)",
            "value": 1184.2657848088484,
            "unit": "ns"
          },
          {
            "name": "find_match (n=500)",
            "value": 5819.259579324836,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=10)",
            "value": 135.36033827399996,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=50)",
            "value": 611.3418089942346,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=100)",
            "value": 1221.5387206467592,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=500)",
            "value": 5967.598090076503,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=10)",
            "value": 135.09800637629388,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=50)",
            "value": 564.1375510178298,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=100)",
            "value": 1113.966461240956,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=500)",
            "value": 5543.609018328,
            "unit": "ns"
          },
          {
            "name": "add+remove (n=100)",
            "value": 6345.216975818594,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=10)",
            "value": 1542.6141779582867,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=50)",
            "value": 6232.292296879645,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=100)",
            "value": 12702.058799625049,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=500)",
            "value": 75687.28606683332,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=10)",
            "value": 494.8385203446412,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=50)",
            "value": 2028.6786304716936,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=100)",
            "value": 3906.66124787554,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=500)",
            "value": 18208.176515763833,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_10_levels",
            "value": 7275.703713262984,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_50_levels",
            "value": 134820.82858569044,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_100_levels",
            "value": 518206.8230250517,
            "unit": "ns"
          },
          {
            "name": "find_match_alloc (n=100)",
            "value": 1144.6810317041175,
            "unit": "ns"
          }
        ]
      }
    ]
  }
}