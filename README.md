# リポジトリについて
前立腺がん診断支援システムのために開発した機械学習モデルのソースコードのをアップロードしています。

学習データセットについては権利関係上アップロードしていません。

## 本モデルの何がすごいのか

通常の機械学習モデルでは、画像中のある領域の検出をしたい場合は、教師データとして正解となる画像中の領域を与えてやる必要がある。

本モデルでは、位置座標(点)を学習して、求めたい領域を出力することができる。

具体的に言えば、前立腺癌が疑われる箇所(点)を学習して、前立腺癌が疑われる領域を検出するモデルを生成することができるモデルとなっている。

![image](https://user-images.githubusercontent.com/89577008/192118955-0d4db3c0-1294-4982-b7dc-c19933c6a2c2.png)

## 各ファイルの説明
* __model.ipynb__

    学習モデルの定義とその学習を行っているスクリプト
* __create_map.ipynb__

    学習後のモデルを使用して前立腺がんの確率マップを出力するスクリプト

* __eval_model.ipynb__

    学習に用いていないデータ(validation data)によるモデルの評価を行うスクリプト

* __trained_model.plt__

    学習済みモデルの重み

# 前立腺がん診断支援AIについて
## 開発背景
![image](https://user-images.githubusercontent.com/89577008/192114457-e647a4d7-b6cf-4044-ac11-36ff30042e86.png)
![image](https://user-images.githubusercontent.com/89577008/192114761-6e926109-6e62-4ac7-892e-ffaf13951ea0.png)
## 開発したシステム
![image](https://user-images.githubusercontent.com/89577008/192114550-09a48f43-8ef7-46df-a5d3-d4146d2c6a33.png)
![image](https://user-images.githubusercontent.com/89577008/192114555-2612b63d-6b5a-4fc9-9eb9-cfa236cafe29.png)
## 本システムの新規性
![image](https://user-images.githubusercontent.com/89577008/192114603-3d337f72-3706-49e4-9680-92ede71ff945.png)
![image](https://user-images.githubusercontent.com/89577008/192114606-84240991-e2d9-4e56-89a0-ec86572abeb2.png)
## モデル設計
![image](https://user-images.githubusercontent.com/89577008/192114612-bef8275d-a6f7-4ab7-919f-1150d6c9f790.png)
![image](https://user-images.githubusercontent.com/89577008/192114620-fc60b34e-2cde-4228-ba62-2d37f603b432.png)
![image](https://user-images.githubusercontent.com/89577008/192114627-af51a11c-625b-43bd-bd60-27a7e5850c3a.png)
![image](https://user-images.githubusercontent.com/89577008/192114639-24d575c3-4dca-487f-85d2-b07dee8b2d89.png)
![image](https://user-images.githubusercontent.com/89577008/192114646-c89a7c93-adef-4535-a0a7-615e6f898e31.png)
## まとめ
![image](https://user-images.githubusercontent.com/89577008/192114661-97a1084f-6bd9-4d34-96f5-9cc88ca87c4d.png)
![image](https://user-images.githubusercontent.com/89577008/192114730-f2457b3e-e483-4fde-80fd-036f2bf251cd.png)
