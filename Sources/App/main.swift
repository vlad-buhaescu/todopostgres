import Vapor
import VaporPostgreSQL
import PostgreSQL

class Task : NodeRepresentable {
    var id :Int?
    var title :String!
    
    func makeNode(context: Context) throws -> Node {
        return try! Node(node: ["id":self.id, "title":self.title])
    }
    
    init(dictionary: [String:Node]) {
        guard let id = dictionary["id"]?.int,
            let title = dictionary["title"]?.string else {
                return
        }
        self.id = id
        self.title = title
    }
}

let drop = Droplet()

do {
    try drop.addProvider(VaporPostgreSQL.Provider.self)

} catch let error {
    print("failed with error \(error)")
}


let postgreSQL = PostgreSQL.Database(dbname: "taskdb", user: "vlad-constantibuhaescu", password: "asdfgqw12")

drop.get("version") { request in
    
    let versionArray = try postgreSQL.execute("SELECT version()")
    
    guard let dictionary = versionArray.first else {
        fatalError("Version not found")
    }
    
    let version = dictionary["version"]
    return try! JSON(node: version)
}

drop.get("tasks","all") { request in
    
    var tasks = [Task]()
    
    let result = try postgreSQL.execute("SELECT * FROM tasks;")
    
    for dictionary in result {
        let task = Task(dictionary: dictionary)
        tasks.append(task)
    }
    return try! JSON(node: tasks)
}

drop.post("tasks","insert") { request in
    
    let connection = try postgreSQL.makeConnection()
    
    guard let title = request.json?["title"]?.string else {
        fatalError("title is missing")
    }
    let result = try postgreSQL.execute("INSERT INTO tasks(title) VALUES($1) RETURNING id; ",[title.makeNode()], on: connection)
    return "Succes"
    
}

drop.run()
