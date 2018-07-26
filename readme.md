Query parser to for Couchbase Lite 2 which converts something like
```
SELECT name.first, name.last WHERE grade = 12 AND gpa >= $GPA
```
to
```
["SELECT", {
    "WHAT": [
        [".", "name", "first"],
        [".", "name", "last"]
    ],
    "WHERE":
        ["AND",
            ["=",
                [".", "grade"],
                12],
            [">=",
                [".", "gpa"],
                ["$", "GPA"] ]
        ]
}]
```
