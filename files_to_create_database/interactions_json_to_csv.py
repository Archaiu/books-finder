import json 
import csv

id_hash = {}
curr_id = 0
line_n = 0

input_path = "data_to_projects/goodreads_interactions_fantasy_paranormal.json"
output_path = "data_to_projects/goodreads_interactions_fantasy_paranormal.csv"

with open(input_path, 'r') as input:
    with open(output_path, 'w') as output:
        writer = csv.writer(output)
        writer.writerow(["user_id,book_id,rating,review_id"])
        for row in input:
            line = json.loads(row)
            user_id_text = line.get("user_id")
            book_id = line.get("book_id")
            review_id = line.get("review_id")
            rating = line.get("rating")

            if user_id_text in id_hash:
                user_id = id_hash[user_id_text]
            else:
                id_hash[user_id_text]=curr_id
                user_id=curr_id
                curr_id+=1
            line_n +=1

            writer.writerow([user_id, book_id, rating, review_id])

            if not line_n % 100000 : print(f"curr_id = {curr_id}, line = {line_n}")