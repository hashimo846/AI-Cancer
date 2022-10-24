# 実行手順書

## 事前情報
* 使用するファイルは2022/06/22に岸本先生から受けった新たなデータ
* 同一患者のファイルは同じファイルに日付ごとに分けられて保存されている
* 各データのROIに関するレビュー情報が入ったExcelファイルが別に存在する
  
## ディレクトリに関して
* 匿名化済みNIfTIファイルの保存先：`/export/hashimoto/DATA/anon_prostate20220627/`
* 結果ファイルの保存先：`/export/hashimoto/Matlab/ResultFiles/Results/`
* ログファイルの出力先：`/export/hashimoto/Matlab/ResultFiles/Logs/`
  
## 実行手順
1. NIfTIファイルから必要データを抽出してMatファイル化

     Matlabで`extract_data`を実行

2. ROIが描画された画像にマニュアルでROIの位置を設定

    Matlabで`set_roi`を実行

3. ROI画像を含む全画像のFOVと画像サイズを統一
   
   1.  Matlabで`fit_images`を実行
   2.  overlay画像を確認しレジストレーション失敗している画像を`Logs/fit_images/error`にコピーする
   3.  Matlabで`fit_error`を実行して、MatFileの除外と結果をCSVに出力する
   
4. セグメンテーション用のNIfTIの生成
   
    Matlabで`make_seg_input`を実行 

5. 前立腺セグメンテーション

   1. `make_seg_input`を`/export/hashimoto/DockerMount/`に移動

   2. GPUサーバーにて次を実行してDocker起動

        ```bash
        export dockerImage=nvcr.io/nvidia/clara-train-sdk:v4.0
        export proxy=http://133.63.21.99:8080//
        docker run --shm-size=1G --ulimit memlock=-1 --ulimit stack=67108864 -it --rm --gpus=all -e HTTPS_PROXY=$proxy -e HTTP_PROXY=$proxy -v /export/hashimoto/DockerMount:/workspace/DockerMount $dockerImage /bin/bash
        ```

   3. データをisovoxel化

        ```bash
        medl-dataconvert -d /workspace/DockerMount/make_seg_input/ -r 1 -s .nii -e .nii.gz -o /workspace/DockerMount/converted_data/
        ```
        
   4. 環境ファイルを変更


        `/workspace/DockerMount/files/config/environment.json`を次に変更

        ```json
        {
            "DATA_ROOT": "/workspace/DockerMount/converted_data",
            "DATASET_JSON": "/workspace/DockerMount/make_seg_input/seg_input.json",
            "PROCESSING_TASK": "segmentation",
            "MMAR_EVAL_OUTPUT_PATH": "eval",
            "MMAR_CKPT_DIR": "models",
            "MMAR_CKPT": "models/model.pt",
            "MMAR_TORCHSCRIPT": "models/model.ts"
        }   
        ```
   5. セグメンテーション
    
        ```bash
        /workspace/DockerMount/files/commands/infer.sh
        ```

        結果が`/workspace/DockerMount/files/eval/`に出力される

6. 前立腺の位置計算

    Matlabで`find_center`を実行

7.  正規化

    Matlabで`standardize`を実行

8.  対象スライス抽出

    1.  Matlabで`extract_slice`を実行
    2.  Matlabで`extract_error`を実行してエラーデータをCSV化
    3.  実行結果のログを参照して、撮像範囲がずれている例のMatファイルを`Results/extract_slice/`から`Results/extract_slice/error`に移動する


9.  前立腺の位置を中心にクロップ
    
    Matlabで`crop_center`を実行
     

10. 学習データセット出力

    Matlabで`make_dataset`を実行

    出力データはIDと切り離されて匿名化された状態で保存され、対応関係はLogに保存される。
