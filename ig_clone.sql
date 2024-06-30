use ig_clone;
/* 1) How many times does the average user post*/

SELECT AVG(post_count) AS average_posts_per_user
FROM (
    SELECT user_id, COUNT(*) AS post_count
    FROM photos
    GROUP BY user_id
) user_post_counts;
-- NO REFERENCE TO THE OUTER QUERY

/* 2) Find the top 5 most used hashtags. */

SELECT tag_name, COUNT(*) AS tag_count
FROM tags
JOIN photo_tags ON tags.id = photo_tags.tag_id
GROUP BY tag_name
ORDER BY tag_count DESC
LIMIT 5;
-- all the photos with the same hashtag will be put together in a group. 

/*3) Find users who have liked every single photo on the site. */

SELECT user_id, COUNT(DISTINCT photo_id) AS liked_photos
FROM likes
GROUP BY user_id                                              -- LIKE OF EACH USER
HAVING liked_photos = (SELECT COUNT(DISTINCT id) FROM photos);


/*4) Retrieve a list of users along with their usernames and the rank of their account creation, ordered by 
the creation date in ascending order.*/

SELECT username, created_at, RANK() OVER (ORDER BY created_at ASC) AS account_rank
FROM users;


/*5) List the comments made on photos with their comment texts, photo URLs, and usernames of users who posted the comments. Include the comment
 count for each photo */
 
 
WITH CommentInfo AS (
    SELECT 
        c.comment_text,
        p.image_url AS photo_url,
        u.username AS user_username,
        c.photo_id,
        COUNT(c.id) AS comment_count
    FROM comments c
    JOIN photos p ON c.photo_id = p.id
    JOIN users u ON c.user_id = u.id
    GROUP BY c.comment_text, p.image_url, u.username, c.photo_id
)

SELECT comment_text, photo_url, user_username, comment_count
FROM CommentInfo
ORDER BY photo_url;


/*6) For each tag, show the tag name and the number of photos associated with that tag. 
Rank the tags by the number of photos in descending order.*/

SELECT t.tag_name, COUNT(pt.photo_id) AS photo_count
FROM tags t
LEFT JOIN photo_tags pt ON t.id = pt.tag_id
GROUP BY t.tag_name
ORDER BY photo_count DESC;

WITH TagPhotoCounts AS (
    SELECT t.tag_name, COUNT(pt.photo_id) AS photo_count
    FROM tags t
    LEFT JOIN photo_tags pt ON t.id = pt.tag_id
    GROUP BY t.tag_name
)

SELECT tag_name, photo_count, RANK() OVER (ORDER BY photo_count DESC) AS tag_rank
FROM TagPhotoCounts;

-- count how many times each tag is associated with photos. We group the results by tag name.

/*7) List the usernames of users who have posted photos along with the count of photos they have posted. Rank them by the number 
of photos in descending order.*/

WITH UserPhotoCounts AS (
    SELECT u.username, COUNT(p.id) AS photo_count
    FROM users u
    LEFT JOIN photos p ON u.id = p.user_id
    GROUP BY u.username
)

SELECT username, photo_count, RANK() OVER (ORDER BY photo_count DESC) AS user_rank
FROM UserPhotoCounts;


 /*8) Display the username of each user along with the creation date of their first posted photo and the 
 creation date of their next posted photo.*/
 -- This helps us identify the order in which photos were uploaded by each user.
 -- ROW_NUMBER() function to assign a rank to each photo based on the user's ID and the photo's creation date. 
WITH UserPhotosOrdered AS (
    SELECT
        u.id AS user_id,
        u.username,
        p.created_at,
        ROW_NUMBER() OVER (PARTITION BY u.id ORDER BY p.created_at) AS photo_rank
    FROM users u
    JOIN photos p ON u.id = p.user_id
)

SELECT
    u.username,
    up_first.created_at AS first_photo_created,
    up_next.created_at AS next_photo_created
FROM users u
LEFT JOIN UserPhotosOrdered up_first ON u.id = up_first.user_id AND up_first.photo_rank = 1
LEFT JOIN UserPhotosOrdered up_next ON u.id = up_next.user_id AND up_next.photo_rank = 2;


-- We use LEFT JOIN to connect the users to the "UserPhotosOrdered" CTE (Common Table Expression) twice: 
-- once for the first photo (photo_rank = 1) and once for the second photo (photo_rank = 2).



/*9) For each comment, show the comment text, the username of the commenter, 
and the comment text of the previous comment made on the same photo.*/

WITH CommentWithPrevious AS (
    SELECT
        c.comment_text,
        u.username AS commenter_username,
        LAG(c.comment_text) OVER (PARTITION BY c.photo_id ORDER BY c.created_at) AS previous_comment_text
    FROM comments c
    JOIN users u ON c.user_id = u.id
)

SELECT
    comment_text,
    commenter_username,
    previous_comment_text
FROM CommentWithPrevious;


/*10) Show the username of each user along with the number of photos they have posted and 
the number of photos posted by the user before them and after them, based on the creation date.*/

WITH UserPhotoCounts AS (
    SELECT
        u.id AS user_id,
        u.username,
        COUNT(p.id) AS photo_count
    FROM users u
    LEFT JOIN photos p ON u.id = p.user_id
    GROUP BY u.id, u.username
)

SELECT
    u.username,
    up.photo_count AS photos_posted,
    LAG(up.photo_count) OVER (ORDER BY u.created_at) AS photos_before,
    LEAD(up.photo_count) OVER (ORDER BY u.created_at) AS photos_after
FROM UserPhotoCounts up
JOIN users u ON up.user_id = u.id
ORDER BY up.username;
