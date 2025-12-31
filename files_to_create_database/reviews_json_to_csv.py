import json
import csv

path = "data_to_projects/"



with open( path + "goodreads_reviews_fantasy_paranormal.json", 'r', encoding="utf-8") as input:
    with open( path + "goodreads_reviews_fantasy_paranormal.csv", 'w', encoding="utf-8") as output:
        writer = csv.writer(output)
        counter = 0
        writer.writerow(["detail, popularity, review_id"])

        for row in input:
            json_row = json.loads(row)
            review_id = json_row.get("review_id")
            detail = json_row.get("review_text")
            popularity = json_row.get("n_votes")

            writer.writerow([detail, popularity, review_id])
            counter+=1

            if not counter % 10000:
                print(str(counter * 10000) + " data completed")
