//
//  ViewController.swift
//  MyRecipe
//
//  Created by FromF on 2016/09/15.
//  Copyright © 2016年 Swift-Beginners. All rights reserved.
//

import UIKit
import SafariServices

// MovableTypeの定義
// (下記の定義を必要に応じて書き換えする)

// ホスト名
let mtHost = "your-host"

// MovableTypeパス
let mtPath = "path-to-mt"

class ViewController: UIViewController , UISearchBarDelegate , UITableViewDataSource , UITableViewDelegate , SFSafariViewControllerDelegate {

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    
    // Search Barのdelegate通知先を設定する
    searchText.delegate = self
    // 入力のヒントになる、プレースホルダを設定する
    searchText.placeholder = "検索したいレシピを入力してください"
    
    // Table ViewのdataSourceを設定
    tableView.dataSource = self
    
    // Table Viewのdelegateを設定
    tableView.delegate = self
    
    // 一覧表示
    searchRecipe(keyword: "")
}

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  @IBOutlet weak var searchText: UISearchBar!
  @IBOutlet weak var tableView: UITableView!

  // お菓子のリスト（タプル配列）
  var recipeList : [(category:String , name:String , link:String , image:String)] = []
  
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    // キーボードを閉じる
    view.endEditing(true)
    // デバックエリアに出力
    print(searchBar.text!)
    
    if let searchWord = searchBar.text {
      // 入力値がnilでなかったら、お菓子を検索
      searchRecipe(keyword: searchWord)
    }
  }
  
  // searchRecipeメソッド
  // 第一引数：keyword 検索したいワード
  func searchRecipe(keyword : String) {
    //レシピの検索キーワードをURLエンコードする
    let keyword_encode = keyword.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
    
    // URLオブジェクトの生成
    var URL = Foundation.URL(string: "http://\(mtHost)/\(mtPath)/mt-data-api.cgi/v3/search?search=\(keyword_encode!)")

    if (keyword.isEmpty) {
        // キーワードがない場合
        URL = Foundation.URL(string: "http://\(mtHost)/\(mtPath)/mt-data-api.cgi/v3/sites/1/entries")
    }
    
    // リンクオブジェクトの生成
    let req = URLRequest(url: URL!)
    
    // セッションの接続をカスタマイズできる
    // タイムアウト値、キャッシュポリシーなどが指定できる。今回は、デフォルト値を使用
    let configuration = URLSessionConfiguration.default
    
    // セッション情報を取り出し
    let session = URLSession(configuration: configuration, delegate: nil, delegateQueue: OperationQueue.main)
    
    // リクエストをタスクとして登録
    let task = session.dataTask(with: req, completionHandler: {
      (data , request , error) in
      // do try catch エラーハンドリング
      do {
        // 受け取ったJSONデータをパース（解析）して格納します
        let json = try JSONSerialization.jsonObject(with: data!) as! [String:Any]
        
        //print("count = \(json["count"])")
        
        // お菓子のリストを初期化
        self.recipeList.removeAll()
        
        // お菓子の情報が取得できているか確認
        if let items = json["items"] as? [[String:Any]] {
          
          // 取得しているお菓子の数だけ処理
          for item in items {
            // カテゴリー名
            var category = ""
            if let categories = item["categories"] as? [[String:Any]] {
                guard let label = categories[0]["label"] as? String else {
                    continue
                }
                category = label
            }
            // レシピの名称
            guard let name = item["title"] as? String else {
              continue
            }
            // 掲載URL
            // urlからlinkに名称を変更しているのでご注意ください
            guard let link = item["permalink"] as? String else {
              continue
            }
            // 画像URL
            var image = ""
            if let assets = item["assets"] as? [[String:Any]] {
                guard let thumnail = assets[0]["thumbnailUrl"] as? String else {
                    continue
                }
                image = thumnail
            }
            
            // １つのレシピをタプルでまとめて管理
            let recipe = (category,name,link,image)
            // お菓子の配列へ追加
            self.recipeList.append(recipe)
            
          }
        }
        
        print ("----------------")
        
        //Table Viewを更新する
        self.tableView.reloadData()
        
      } catch {
        // エラー処理
        print("エラーが出ました")
      }
    })
    // ダウンロード開始
    task.resume()
  }
  
  // Cellの総数を返すdatasourceメソッド、必ず記述する必要があります
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    // レシピリストの総数
    return recipeList.count
  }
  
  // Cellに値を設定するdatasourceメソッド。必ず記述する必要があります
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    //今回表示を行う、Cellオブジェクト（１行）を取得する
    let cell = tableView.dequeueReusableCell(withIdentifier: "recipeCell", for: indexPath)
    
    // お菓子のタイトル設定
    cell.textLabel?.text = "\(recipeList[indexPath.row].name)(\(recipeList[indexPath.row].category))"
    
    // お菓子画像のURLを取り出す
    let url = URL(string: recipeList[indexPath.row].image)
    
    // URLから画像を取得
    if let image_data = try? Data(contentsOf: url!) {
      // 正常に取得できた場合は、UIImageで画像オブジェクトを生成して、Cellにお菓子画像を設定
      cell.imageView?.image = UIImage(data: image_data)
    }
    
    // 設定済みのCellオブジェクトを画面に反映
    return cell
  }
  
  // Cellが選択された際に呼び出されるdelegateメソッド
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    // ハイライト解除
    tableView.deselectRow(at: indexPath, animated: true)
    
    // URLをstring → URL型に変換
    let urlToLink = URL(string: recipeList[indexPath.row].link)
    
    // SFSafariViewを開く
    let safariViewController = SFSafariViewController(url: urlToLink!)
    
    // delegateの通知先を自分自身
    safariViewController.delegate = self
    
    // SafariViewが開かれる
    present(safariViewController, animated: true, completion: nil)
  }
  
  // SafariViewが閉じられた時に呼ばれるdelegateメソッド
  func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
    // SafariViewを閉じる
    dismiss(animated: true, completion: nil)
  }
}

