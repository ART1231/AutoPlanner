//
//  table.swift
//  AutoPlanner
//
//  Created by 荒田大輔 on 2021/11/08.
//

import UIKit
import EventKit
 
class TableController: UIViewController ,UITableViewDataSource, UITableViewDelegate{
    
    @IBOutlet weak var table: UITableView!
    
    @IBAction func clearButton(_ sender: Any) {
        userDefaults.removeObject(forKey: "tasks")
        self.loadView()
        self.viewDidLoad()
    }
    
    
    let userDefaults = UserDefaults.standard
    var isEmpty = true
    //let tasks = [["a","i","u","e","o" ]]
    
    override func viewWillAppear(_ animated: Bool) {
        table.reloadData()
        //super.viewDidAppear(animated)
        //userDefaults.removeObject(forKey: "tasks")
        //tasks = userDefaults.array(forKey: "tasks")! as? [[String]]
    }
    
    //Table Viewのセルの数を指定
    func tableView(_ table: UITableView,numberOfRowsInSection section: Int) -> Int {
        if let tasks = userDefaults.array(forKey: "tasks") as? [[String]]{
            return tasks.count
        } else {
            return 0
        }

        //} else {
        //    return 0
        //}
    }
    
    //各セルの要素を設定する
    func tableView(_ table: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tasks = userDefaults.array(forKey: "tasks") as? [[String]]
        // tableCell の ID で UITableViewCell のインスタンスを生成
        let cell = table.dequeueReusableCell(withIdentifier: "tableCell", for: indexPath)
        
        let label1 = cell.viewWithTag(1) as! UILabel
        label1.text = "No." + String(indexPath.row + 1)
            
        let name = cell.viewWithTag(2) as! UILabel
        name.text = "予定名: \(tasks![indexPath.row][0])"
            
        let date = cell.viewWithTag(3) as! UILabel
        date.text = tasks![indexPath.row][1] + " 〜 " + tasks![indexPath.row][2]
            
        let time = cell.viewWithTag(4) as! UILabel
        time.text = tasks![indexPath.row][3] + " 〜 " + tasks![indexPath.row][4]
        
        let taskName = tasks![indexPath.row][0]
        let startDate = tasks![indexPath.row][1]
        let endDate = tasks![indexPath.row][2]
        let startTime = tasks![indexPath.row][3]
        let endTime = tasks![indexPath.row][4]
            
        let keyWord = taskName + startDate + endDate + startTime + endTime
        let eventsIdentifier = userDefaults.array(forKey: keyWord)! as? [String]
        let eventStore = EKEventStore()
        var passedTime = 0
        if (eventsIdentifier!.isEmpty == false){
            for eventIdentifier in eventsIdentifier! {
                if let event = eventStore.event(withIdentifier: eventIdentifier) {
                    if event.startDate < Date() {
                        if event.endDate < Date() {
                            passedTime += Int(event.endDate.timeIntervalSince(event.startDate))
                        } else {
                            passedTime += Int(Date().timeIntervalSince(event.startDate))
                        }
                    }
                }
            }
        }
        
        let hour:Int = passedTime/3600
        let minute:Int = passedTime%3600/60
        
        let alltime = cell.viewWithTag(5) as! UILabel
        alltime.text = "\(hour) 時間 \(minute) 分 / \(tasks![indexPath.row][5])  経過"
        
        
        return cell
        

    }
    // Cell の高さを１２０にする
    func tableView(_ table: UITableView,heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150.0
    }
    
    //セルの編集許可
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
           return true
    }
    
       //スワイプしたセルを削除
    func tableView(_ tableView: UITableView, commit editingStyle:UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        var tasks = userDefaults.array(forKey: "tasks")! as? [[String]]
        print("tasks", tasks!)
        
        if editingStyle == UITableViewCell.EditingStyle.delete {
            deleteEvent()
            tasks!.remove(at: indexPath.row)
            userDefaults.set(tasks, forKey: "tasks")
            //tableView.deleteRows(at: [indexPath], with:UITableView.RowAnimation.automatic)
            tableView.reloadData()
        }
    
        func deleteEvent() {
            let taskName = tasks![indexPath.row][0]
            let startDate = tasks![indexPath.row][1]
            let endDate = tasks![indexPath.row][2]
            let startTime = tasks![indexPath.row][3]
            let endTime = tasks![indexPath.row][4]
            
            //全てのカレンダーに対して検索
            let keyWord = taskName + startDate + endDate + startTime + endTime
            let eventsIdentifier = userDefaults.array(forKey: keyWord)! as? [String]
            let eventStore = EKEventStore()
            if (eventsIdentifier!.isEmpty == false){
                for eventIdentifier in eventsIdentifier! {
                    if let event = eventStore.event(withIdentifier: eventIdentifier) {
                        do {
                            try eventStore.remove(event, span: .thisEvent)
                        }
                        catch let error {
                            print (error)
                        }
                    }
                }
            }
        }
        
        func connect(day:String, time:String) -> Date{
            let stringDate:String = day + " " + time
            let format = DateFormatter()
            format.locale = Locale(identifier: "ja_JP")
            format.timeZone = TimeZone(identifier: "Asia/Tokyo")
            format.dateFormat = "yyyy/MM/dd HH:mm"
            if let date:Date = format.date(from: stringDate){
                return date
            } else{
                return Date()
            }
        }
    }
}
