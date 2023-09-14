import UIKit
import SnapKit
import UserNotifications
class Reminder: Codable, Equatable {
    static func == (lhs: Reminder, rhs: Reminder) -> Bool {
        return lhs.text == rhs.text && lhs.date == rhs.date
    }
    var text: String
    var date: Date
    init(text: String, date: Date) {
        self.text = text
        self.date = date
    }
}
class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var reminders: [Reminder] = []
    var filteredReminders: [Reminder] = []
    let tableView = UITableView()
    let emptyStateImageView = UIImageView()
    let emptyStateLabel = UILabel()
    let searchBar = UISearchBar()
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Напоминания"
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        tableView.dataSource = self
        tableView.delegate = self
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addReminder))
        let deleteButton = UIBarButtonItem(image: UIImage(systemName: "trash"), style: .plain, target: self, action: #selector(deleteButtonTapped))
        navigationItem.leftBarButtonItem = deleteButton
        configureEmptyStateView()
        setupSearchBar()
        if let savedRemindersData = UserDefaults.standard.data(forKey: "reminders"),
           let savedReminders = try? JSONDecoder().decode([Reminder].self, from: savedRemindersData) {
            reminders = savedReminders
            filteredReminders = reminders
        }
        updateEmptyStateViewVisibility()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    @objc func addReminder() {
        let addViewController = AddViewController()
        addViewController.delegate = self
        navigationController?.pushViewController(addViewController, animated: true)
    }
    @objc func configureEmptyStateView() {
        emptyStateImageView.image = UIImage(named: "page-removebg-preview")
        view.addSubview(emptyStateImageView)
        emptyStateImageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.equalTo(200)
            $0.height.equalTo(200)
        }
        emptyStateLabel.text = "Пока здесь ничего нет"
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.font = UIFont.boldSystemFont(ofSize: 20)
        emptyStateLabel.textColor = .black
        view.addSubview(emptyStateLabel)
        emptyStateLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(emptyStateImageView.snp.bottom).offset(20)
        }
    }
    @objc func deleteButtonTapped() {
        if filteredReminders.isEmpty {
            let alert = UIAlertController(title: "Еще пока нет напоминаний", message: "Добавьте новое напоминание", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            present(alert, animated: true, completion: nil)
        } else {
            filteredReminders.removeAll()
            tableView.reloadData()
            updateEmptyStateViewVisibility()
        }
    }
    func updateEmptyStateViewVisibility() {
        if filteredReminders.isEmpty {
            emptyStateImageView.isHidden = false
            emptyStateLabel.isHidden = false
        } else {
            emptyStateImageView.isHidden = true
            emptyStateLabel.isHidden = true
        }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredReminders.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        let reminder = filteredReminders[indexPath.row]
        cell.textLabel?.text = reminder.text
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm"
        cell.detailTextLabel?.text = dateFormatter.string(from: reminder.date)
        return cell
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let removedReminder = filteredReminders.remove(at: indexPath.row)
            if let indexInReminders = reminders.firstIndex(of: removedReminder) {
                reminders.remove(at: indexInReminders)
            }
            tableView.deleteRows(at: [indexPath], with: .automatic)
            saveRemindersToUserDefaults()
            updateEmptyStateViewVisibility()
        }
    }
    func setupSearchBar() {
        searchBar.delegate = self
        searchBar.showsCancelButton = true
        searchBar.placeholder = "Поиск"
        searchBar.searchBarStyle = .minimal
        searchBar.sizeToFit()
        tableView.tableHeaderView = searchBar
    }
}
extension ViewController: AddDelegate {
    func didAdd(reminder: Reminder) {
        reminders.append(reminder)
        filteredReminders.append(reminder)
        tableView.reloadData()
        saveRemindersToUserDefaults()
        updateEmptyStateViewVisibility()
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "Напоминание"
        content.body = reminder.text
        content.sound = .default
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    func saveRemindersToUserDefaults() {
        if let encodedReminders = try? JSONEncoder().encode(reminders) {
            UserDefaults.standard.set(encodedReminders, forKey: "reminders")
        }
    }
}
extension ViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredReminders = reminders.filter { $0.text.lowercased().contains(searchText.lowercased()) }
        tableView.reloadData()
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        filteredReminders = reminders
        tableView.reloadData()
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
protocol AddDelegate: AnyObject {
    func didAdd(reminder: Reminder)
}
class AddViewController: UIViewController {
    var delegate: AddDelegate?
    let reminderTextField = UITextField()
    let datePicker = UIDatePicker()
    let saveButton = UIButton()
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Добавить напоминание"
        view.backgroundColor = .white
        view.addSubview(reminderTextField)
        view.addSubview(datePicker)
        view.addSubview(saveButton)
        reminderTextField.snp.makeConstraints {
            $0.centerY.centerX.equalToSuperview()
            $0.height.equalTo(40)
        }
        reminderTextField.placeholder = "Текст напоминания"
        datePicker.snp.makeConstraints {
            $0.top.equalTo(reminderTextField.snp.bottom).offset(20)
            $0.centerX.equalToSuperview()
        }
        saveButton.snp.makeConstraints {
            $0.top.equalTo(datePicker.snp.bottom).offset(20)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(40)
            $0.width.equalTo(120)
        }
        saveButton.setTitle("Сохранить", for: .normal)
        saveButton.backgroundColor = .blue
        saveButton.addTarget(self, action: #selector(saveReminder), for: .touchUpInside)
    }
    @objc private func saveReminder() {
        guard let text = reminderTextField.text, !text.isEmpty else {
            return
        }
        let date = datePicker.date
        let reminder = Reminder(text: text, date: date)
        delegate?.didAdd(reminder: reminder)
        navigationController?.popViewController(animated: true)
    }
}
