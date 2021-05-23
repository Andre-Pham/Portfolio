//
//  PerformanceCollectionViewController.swift
//  portfolio
//
//  Created by Andre Pham on 23/5/21.
//

import UIKit

private let reuseIdentifier = "Cell"

// https://stackoverflow.com/questions/31735228/how-to-make-a-simple-collection-view-with-swift
class PerformanceCollectionViewController: UICollectionViewController {
    
    let CELL_WIDE = "wideCell"
    let CELL_SINGLE = "singleCell"
    let CELL_TALL = "tallCell"
    var items = ["1", "2", "3", "4", "5", "6", "7"]
    let WIDE_CELL_INDICES = [0]
    let SINGLE_CELL_INDICES = [1, 2, 3, 4]
    let TALL_CELL_INDICES = [5, 6]

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        collectionView!.contentInset = UIEdgeInsets(top: 5, left: 15, bottom: 20, right: 15)
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 15 // spacing left/right
        layout.minimumLineSpacing = 15 // spacing up/down
        self.collectionView.frame = self.view.frame
        self.collectionView.collectionViewLayout = layout

        // Do any additional setup after loading the view.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.items.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if self.WIDE_CELL_INDICES.contains(indexPath.row) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_WIDE, for: indexPath as IndexPath) as! WidePerformanceCollectionViewCell
            
            cell.titleLabel.text = "Average\nAnnual\nReturn"
            cell.percentGainLabel.text = "+300.0%"
            
            cell.titleLabel.font = CustomFont.setSubtitle2Font()
            cell.percentGainLabel.font = CustomFont.setLargeFont()
            
            cell.backgroundColor = UIColor(named: "GreyBlack1")
            cell.percentGainLabel.textColor = UIColor(named: "Green1")
        
            return cell
        }
        else if self.SINGLE_CELL_INDICES.contains(indexPath.row) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_SINGLE, for: indexPath as IndexPath) as! SinglePerformanceCollectionViewCell
            
            cell.titleLabel.text = "Best Growth"
            cell.tickerLabel.text = "MMMM"
            cell.percentGainLabel.text = "-10.24%"
            
            cell.titleLabel.font = CustomFont.setFont(size: CustomFont.BODY_SIZE, style: CustomFont.BODY_STYLE, weight: .bold)
            cell.tickerLabel.font = CustomFont.setLarge2Font()
            cell.percentGainLabel.font = CustomFont.setBodyFont()
            
            cell.backgroundColor = UIColor(named: "GreyBlack1")
            
            return cell
        }
        else {
            // self.TALL_CELL_INDICES.contains(indexPath.row)
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_TALL, for: indexPath as IndexPath) as! TallPerformanceCollectionViewCell
            
            cell.titleLabel.text = "Winners"
            
            cell.tickerLabel1.text = "MMMM"
            cell.gainInPercentageLabel1.text = "-10.24%"
            cell.gainInDollarsLabel1.text = "-$10.24"
            
            cell.tickerLabel2.text = "MMMM"
            cell.gainInPercentageLabel2.text = "-10.24%"
            cell.gainInDollarsLabel2.text = "-$10.24"
            
            cell.tickerLabel3.text = "MMMM"
            cell.gainInPercentageLabel3.text = "-10.24%"
            cell.gainInDollarsLabel3.text = "-$10.24"
            
            cell.titleLabel.font = CustomFont.setFont(size: CustomFont.BODY_SIZE, style: CustomFont.BODY_STYLE, weight: .bold)
            
            cell.tickerLabel1.font = CustomFont.setLarge2Font()
            cell.gainInPercentageLabel1.font = CustomFont.setBodyFont()
            cell.gainInDollarsLabel1.font = CustomFont.setBodyFont()
            
            cell.tickerLabel2.font = CustomFont.setLarge2Font()
            cell.gainInPercentageLabel2.font = CustomFont.setBodyFont()
            cell.gainInDollarsLabel2.font = CustomFont.setBodyFont()
            
            cell.tickerLabel3.font = CustomFont.setLarge2Font()
            cell.gainInPercentageLabel3.font = CustomFont.setBodyFont()
            cell.gainInDollarsLabel3.font = CustomFont.setBodyFont()
            
            cell.backgroundColor = UIColor(named: "GreyBlack1")
            
            return cell
        }
        
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}

// https://stackoverflow.com/questions/38028013/how-to-set-uicollectionviewcell-width-and-height-programmatically
extension PerformanceCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if self.WIDE_CELL_INDICES.contains(indexPath.row) {
            let width = UIScreen.main.bounds.width - 15*2
            return CGSize(width: width, height: 100)
        }
        else if self.SINGLE_CELL_INDICES.contains(indexPath.row) {
            let width = (UIScreen.main.bounds.width - 15*3)/2
            return CGSize(width: width, height: 100)
        }
        else {
            // self.TALL_CELL_INDICES.contains(indexPath.row)
            let width = (UIScreen.main.bounds.width - 15*3)/2
            return CGSize(width: width, height: 320)
        }
    }
    
}
