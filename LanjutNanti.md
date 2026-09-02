# app detail

- app name : Lanjut Nanti
- platform : android, ios, desktop (windows, linux)
- short description : Content continuing app
- type : personal

# what this app solves

when i binge watched a serial in browser and stopped at an episode (e.g. i watched doraemon at ep. 5), sometimes i just left it on my browser. then, i forgot about it and closed the tab accidentally. sure browser has history, but it is a pain scrolling/searching through browser history list.

there is also a time where i watched long youtube video (like kajian ust. khalid basalamah that takes 1-2 hrs). then interrupted because of another activity, and left it on my browser/youtube app. then closed the browser tab / youtube app. sometimes youtube does the right thing by continuing where i left off, but sometimes it doesn't.

# how should the app stores its data?

should be offline first app. either sqlite OR just plain csv should suffice. i need your input

# what data should the app store?

USER
//supabase user data. this app should be connected to supabase later on

CONTENT
Content name *required
Tag name links to TAG
Created at
Updated at
User links to USER

CONTENT DETAIL
Content link *required
Note

TAG
Tag name
Created at
Updated at

# how should the app handle backup and restore?

all data except user should be export/import-able via json

# how should the app data work?

1. user creates new content -> let's say I read doraemon chap 5
2. user creates content detail -> i added link for doraemon chap 5
3. user creates new content detail -> let's say tomorrow i read doraemon chap 6 and stopped at chap 7, i added link for doraemon chap 7
4. in the app, the latest content detail should be shown -> when i browse through the content list, app should show "latest : <updatedAt>"

# search is everything

the app provides search bar that looks through content name, tag name, and notes making sure information is accessible

## sample flows

### flow 1: save a manga for the first time

1. User taps **Add content**.
2. User enters `Doraemon` as the content name and assigns the `Manga` tag.
3. The app creates one CONTENT record for Doraemon.
4. User adds a CONTENT DETAIL containing the link to chapter 6 and the note `Finished chapter 5; continue from chapter 6`.
5. The app updates the parent CONTENT's `updated at` value.
6. The content list shows Doraemon with chapter 6 as its latest detail.

### flow 2: continue from the latest manga chapter

1. User opens Doraemon from the content list.
2. The app shows the most recently updated CONTENT DETAIL first.
3. User taps the chapter 6 link and continues reading.
4. After stopping at chapter 7, user adds another CONTENT DETAIL with the chapter 7 link and an optional note.
5. The app keeps the old chapter 6 detail as history and marks the chapter 7 detail as the latest one.
6. The app updates Doraemon's `updated at` value so it moves to the top of a list sorted by recent activity.

### flow 3: save progress in a long video

1. User creates CONTENT named `Kajian Ust. Khalid Basalamah` with the `Video` tag.
2. User stops watching at `00:42:15`.
3. User adds a CONTENT DETAIL containing the video link with its timestamp and the note `Continue at 42:15`.
4. Later, user opens the content and resumes from the latest saved link.
5. User stops again at `01:10:30` and adds a new CONTENT DETAIL for that timestamp.
6. The new detail becomes the latest one, while the earlier timestamp remains in the detail history.

### flow 4: correct a saved detail

1. User notices that the latest saved link is incorrect.
2. User edits that CONTENT DETAIL instead of creating a duplicate.
3. The app updates the detail's link, note, and `updated at` value.
4. The edited detail remains the latest detail for its CONTENT.

### flow 5: add progress while offline

1. User creates or updates content without an internet connection.
2. The app immediately saves the change to its local database.
3. The user can close and reopen the app without losing the change.
4. When Supabase synchronization is added later, the app uploads pending local changes after the user reconnects and signs in.

### flow 6: export and restore data

1. User exports all CONTENT, CONTENT DETAIL, and TAG records to a JSON backup file.
2. User installs the app on another device and signs in.
3. User imports the JSON file.
4. The app validates the file, restores the records and their relationships, and reports any invalid entries.
5. Each content item again shows its most recently updated CONTENT DETAIL.

For these flows, CONTENT DETAIL should also store `created at` and `updated at`. The app can determine the latest detail by sorting details by `updated at` in descending order and selecting the first one.

## sample exportable JSON

```json
{
  "schema_version": 1,
  "exported_at": "2026-09-02T10:30:00+07:00",
  "tags": [
    {
      "id": "tag_manga",
      "name": "Manga",
      "created_at": "2026-08-10T09:00:00+07:00",
      "updated_at": "2026-08-10T09:00:00+07:00"
    },
    {
      "id": "tag_video",
      "name": "Video",
      "created_at": "2026-08-11T13:20:00+07:00",
      "updated_at": "2026-08-11T13:20:00+07:00"
    },
    {
      "id": "tag_book",
      "name": "Book",
      "created_at": "2026-08-14T18:45:00+07:00",
      "updated_at": "2026-08-14T18:45:00+07:00"
    },
    {
      "id": "tag_article",
      "name": "Article",
      "created_at": "2026-08-18T07:30:00+07:00",
      "updated_at": "2026-08-18T07:30:00+07:00"
    }
  ],
  "contents": [
    {
      "id": "content_doraemon",
      "name": "Doraemon",
      "tag_id": "tag_manga",
      "created_at": "2026-08-10T09:05:00+07:00",
      "updated_at": "2026-09-01T20:15:00+07:00"
    },
    {
      "id": "content_kajian_khalid",
      "name": "Kajian Ust. Khalid Basalamah",
      "tag_id": "tag_video",
      "created_at": "2026-08-11T13:25:00+07:00",
      "updated_at": "2026-08-30T21:10:00+07:00"
    },
    {
      "id": "content_clean_code",
      "name": "Clean Code",
      "tag_id": "tag_book",
      "created_at": "2026-08-14T18:50:00+07:00",
      "updated_at": "2026-08-28T19:40:00+07:00"
    },
    {
      "id": "content_rust_book",
      "name": "The Rust Programming Language",
      "tag_id": "tag_article",
      "created_at": "2026-08-18T07:35:00+07:00",
      "updated_at": "2026-08-25T08:20:00+07:00"
    },
    {
      "id": "content_one_piece",
      "name": "One Piece",
      "tag_id": "tag_manga",
      "created_at": "2026-08-20T22:00:00+07:00",
      "updated_at": "2026-08-31T22:30:00+07:00"
    }
  ],
  "content_details": [
    {
      "id": "detail_doraemon_chapter_6",
      "content_id": "content_doraemon",
      "link": "https://example.com/doraemon/chapter-6",
      "note": "Finished chapter 5; continue from chapter 6.",
      "created_at": "2026-08-10T09:10:00+07:00",
      "updated_at": "2026-08-10T09:10:00+07:00"
    },
    {
      "id": "detail_doraemon_chapter_7",
      "content_id": "content_doraemon",
      "link": "https://example.com/doraemon/chapter-7",
      "note": "Continue from chapter 7.",
      "created_at": "2026-09-01T20:15:00+07:00",
      "updated_at": "2026-09-01T20:15:00+07:00"
    },
    {
      "id": "detail_kajian_42_minutes",
      "content_id": "content_kajian_khalid",
      "link": "https://www.youtube.com/watch?v=example&t=2535s",
      "note": "Continue at 42:15.",
      "created_at": "2026-08-11T14:10:00+07:00",
      "updated_at": "2026-08-11T14:10:00+07:00"
    },
    {
      "id": "detail_kajian_70_minutes",
      "content_id": "content_kajian_khalid",
      "link": "https://www.youtube.com/watch?v=example&t=4230s",
      "note": "Continue at 01:10:30.",
      "created_at": "2026-08-30T21:10:00+07:00",
      "updated_at": "2026-08-30T21:10:00+07:00"
    },
    {
      "id": "detail_clean_code_page_86",
      "content_id": "content_clean_code",
      "link": "https://example.com/books/clean-code?page=86",
      "note": "Continue from page 86, Functions chapter.",
      "created_at": "2026-08-28T19:40:00+07:00",
      "updated_at": "2026-08-28T19:40:00+07:00"
    },
    {
      "id": "detail_rust_chapter_4",
      "content_id": "content_rust_book",
      "link": "https://doc.rust-lang.org/book/ch04-00-understanding-ownership.html",
      "note": "Continue with Understanding Ownership.",
      "created_at": "2026-08-25T08:20:00+07:00",
      "updated_at": "2026-08-25T08:20:00+07:00"
    },
    {
      "id": "detail_one_piece_chapter_1158",
      "content_id": "content_one_piece",
      "link": "https://example.com/one-piece/chapter-1158",
      "note": "Continue from chapter 1158.",
      "created_at": "2026-08-31T22:30:00+07:00",
      "updated_at": "2026-08-31T22:30:00+07:00"
    }
  ]
}
```

The export intentionally excludes USER records and `user_id` values. During import, the app should assign every imported CONTENT record to the currently signed-in user. IDs are included so `tag_id` and `content_id` relationships can be restored reliably. `schema_version` allows future app versions to migrate older backup formats before importing them.
