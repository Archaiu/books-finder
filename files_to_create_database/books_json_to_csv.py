import json
import csv

path = "data_to_projects/"

authors = {}

with open( path + "goodreads_book_authors.json", 'r', encoding="utf-8") as f:
    for row in f:
        line = json.loads(row)
        authors[line.get("author_id")]=line.get("name")
print("Authors done")

series = {}

with open(path + "goodreads_book_series.json", 'r', encoding="utf-8") as f:
    for row in f:
        line = json.loads(row)
        series[line.get("series_id")]=line.get("title")
print("Series done")

with open( path + "goodreads_books_fantasy_paranormal.json", 'r', encoding="utf-8") as input:
    with open( path + "goodreads_books_fantasy_paranormal.csv", 'w', encoding="utf-8") as output:
        writer = csv.writer(output)
        counter = 0
        writer.writerow(["id", "title", "pub_year", "num_page", "author", "rating", "serie", "top_tag", "second_tag","third_tag", "desc"])

        for row in input:
            json_row = json.loads(row)
            id = json_row.get("book_id")
            title = json_row.get("title_without_series").split("(")[0].strip()
            author = authors[json_row.get("authors")[0]["author_id"]] if len(json_row.get("authors")) >= 1 else ""
            num_page = json_row.get("num_pages")
            pub_year = json_row.get("publication_year")
            rating = json_row.get("average_rating")
            serie = series[json_row.get("series")[0]] if len(json_row.get("series")) >= 1 else ""
            popular_shelves = json_row.get("popular_shelves")
            top_tag = popular_shelves[0]["name"] if len(popular_shelves)>0 else ""
            secord_tag = popular_shelves[1]["name"] if len(popular_shelves)>1 else ""
            third_tag = popular_shelves[2]["name"] if len(popular_shelves)>2 else ""
            desc = json_row.get('description').replace('\n', ' ').replace('\r', '').replace('\t', '').strip()

            writer.writerow([id, title, pub_year, num_page, author, rating, serie, top_tag, secord_tag, third_tag, desc])
            counter+=1

            if not counter % 10000:
                print(str(counter * 10000) + " data completed")
