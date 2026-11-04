# Account Deletion – Campus Connect

## Ziel

Campus Connect soll Nutzern ermöglichen, ihren eigenen Account vollständig zu löschen.

Bei der Löschung sollen nicht nur das Benutzerprofil und der Firebase-Authentication-Account entfernt werden, sondern auch alle personenbezogenen Inhalte, Beziehungen und Referenzen, die mit der UID des Nutzers verbunden sind.

Der Löschprozess wird serverseitig ausgeführt und soll wiederholbar sein, falls ein einzelner Löschschritt fehlschlägt.

---

## Grundprinzipien

* Die Löschung darf nur vom angemeldeten Nutzer für den eigenen Account gestartet werden.
* Die eigentliche Datenbereinigung erfolgt serverseitig.
* Flutter startet lediglich den Löschvorgang und zeigt dessen Ergebnis an.
* Der Firebase-Authentication-Account wird erst ganz am Ende gelöscht.
* Fehlende oder bereits gelöschte Daten dürfen keinen Abbruch des gesamten Prozesses verursachen.
* Während des Löschprozesses wird der Account mit `accountStatus: deleting` markiert.
* Ein Löschvorgang muss erneut ausgeführt werden können, wenn er teilweise fehlgeschlagen ist.

---

# 1. Admin-Sonderregel

Admin-Dokumente befinden sich unter:

```text
admin/{uid}
```

Ein aktiver Admin besitzt:

```text
active: true
```

### Regeln

* Ein normaler Nutzer darf seinen Account löschen.
* Ein Admin darf seinen Account löschen, wenn danach mindestens ein weiterer aktiver Admin verbleibt.
* Der letzte aktive Admin darf seinen Account nicht löschen.
* Die Prüfung muss serverseitig erfolgen.
* Gleichzeitige Löschvorgänge mehrerer Admins müssen berücksichtigt werden.

Vor Beginn der eigentlichen Löschung soll ein löschbarer Admin aus der Menge der aktiven Admins entfernt bzw. deaktiviert werden.

---

# 2. Posts

Posts befinden sich unter:

```text
posts/{postId}
```

Der Autor wird gespeichert über:

```text
userId
```

Alle Posts mit:

```text
userId == uid
```

müssen gelöscht werden.

### Wichtig

Posts besitzen Subcollections:

```text
posts/{postId}/comments
posts/{postId}/likes
```

Beim Löschen eines Firestore-Dokuments werden dessen Subcollections nicht automatisch gelöscht.

Deshalb muss ein eigener Post inklusive seiner Subcollections vollständig entfernt werden.

---

# 3. Kommentare

Kommentare besitzen ebenfalls:

```text
userId
```

Bei einer Accountlöschung müssen auch Kommentare des Nutzers unter Posts anderer Nutzer gelöscht werden.

Geplante Suche:

```text
collectionGroup("comments")
where userId == uid
```

Die fremden Posts selbst bleiben bestehen.

---

# 4. Likes

Likes besitzen:

```text
userId
```

Alle Likes, die der Nutzer auf fremden Posts gesetzt hat, müssen entfernt werden.

Geplante Suche:

```text
collectionGroup("likes")
where userId == uid
```

Likes auf eigenen Posts verschwinden zusammen mit dem jeweiligen Post.

Falls Like-Zähler separat gespeichert werden, müssen diese entsprechend aktualisiert werden.

---

# 5. Follower und Following

Follow-Beziehungen werden in beide Richtungen gespeichert.

Beispiel:

```text
Julia folgt Dörte

users/JULIA/following/DÖRTE
users/DÖRTE/followers/JULIA
```

Bei der Löschung müssen beide Richtungen entfernt werden.

## Following

Für:

```text
users/{uid}/following/{followedUid}
```

muss zusätzlich gelöscht werden:

```text
users/{followedUid}/followers/{uid}
```

## Followers

Für:

```text
users/{uid}/followers/{followerUid}
```

muss zusätzlich gelöscht werden:

```text
users/{followerUid}/following/{uid}
```

Anschließend werden die eigenen `followers`- und `following`-Subcollections vollständig entfernt.

---

# 6. Notifications

Notifications liegen unter:

```text
users/{receiverUid}/notifications/{notificationId}
```

Sie enthalten unter anderem:

```text
senderId
senderName
senderPhotoUrl
message
postId
```

## Eigene Notifications

Die gesamte Subcollection:

```text
users/{uid}/notifications
```

wird gelöscht.

## Vom Nutzer erzeugte Notifications

Auch Notifications bei anderen Nutzern müssen gelöscht werden, wenn:

```text
senderId == uid
```

Geplante Suche:

```text
collectionGroup("notifications")
where senderId == uid
```

Dadurch werden auch gespeicherter Name, Profilbild-URL und Nachrichtentexte des gelöschten Nutzers entfernt.

---

# 7. FCM Tokens

Push-Tokens befinden sich unter:

```text
users/{uid}/fcmTokens
```

Die gesamte Subcollection wird gelöscht.

Nach einer Accountlöschung darf kein Gerät des ehemaligen Accounts weiterhin als Push-Empfänger registriert sein.

---

# 8. Hidden Posts

Ausgeblendete Posts befinden sich unter:

```text
users/{uid}/hiddenPosts
```

Diese Subcollection wird vollständig gelöscht.

---

# 9. Reports

Reports befinden sich unter:

```text
reports/{reportId}
```

Aktuell wird die Report-ID folgendermaßen erzeugt:

```text
{reporterUserId}_{postId}
```

Ein Report enthält:

```text
postId
reportedUserId
reporterUserId
reason
status
createdAt
```

Damit kann die UID eines Nutzers sowohl in Feldern als auch direkt in der Dokument-ID vorkommen.

## Nutzer hat einen Report erstellt

Falls:

```text
reporterUserId == uid
```

soll der Moderationsvorgang nicht zwingend verloren gehen.

Der Report kann anonymisiert werden.

Da die UID zusätzlich in der Dokument-ID steckt, muss der Report unter einer neuen neutralen Dokument-ID gespeichert und das alte Dokument gelöscht werden.

Mögliche Kennzeichnung:

```text
reporterUserId: null
reporterDeleted: true
```

## Nutzer wurde gemeldet

Falls:

```text
reportedUserId == uid
```

wird die Referenz auf den Nutzer entfernt.

Mögliche Kennzeichnung:

```text
reportedUserId: null
reportedUserDeleted: true
```

Wenn der zugehörige Post ebenfalls gelöscht wurde, wird auch dessen Referenz bereinigt.

Offene Reports, deren gemeldeter Inhalt nicht mehr existiert, können auf `resolved` gesetzt werden.

---

# 10. Profilbild

Der aktuelle Storage-Pfad lautet:

```text
profile_images/{uid}/profile.jpg
```

Zusätzlich besitzt das User-Dokument:

```text
photoUrl
```

Die Löschroutine soll:

1. die in `photoUrl` referenzierte Datei löschen, falls vorhanden,
2. den aktuellen Storage-Pfad `profile_images/{uid}` vollständig bereinigen.

Der ältere Ordner:

```text
profilePictures
```

wird vom aktuellen Code nicht mehr verwendet und gilt als Legacy-Struktur.

---

# 11. Post-Bilder

Post-Bilder befinden sich unter:

```text
post_images/{uid}/...
```

Bei der Accountlöschung werden sämtliche Dateien unter diesem UID-Pfad gelöscht.

---

# 12. User-Dokument

Erst nachdem die Subcollections und externen Referenzen bereinigt wurden, wird gelöscht:

```text
users/{uid}
```

Bekannte Subcollections:

```text
followers
following
notifications
fcmTokens
hiddenPosts
```

Weitere zukünftig hinzukommende Subcollections müssen bei Erweiterungen dieser Dokumentation ergänzt werden.

---

# 13. Firebase Authentication

Der Firebase-Authentication-Account wird als letzter Schritt gelöscht.

```text
Firebase Authentication
└── uid
```

Die UID darf erst entfernt werden, nachdem die zugehörigen Firestore- und Storage-Daten erfolgreich bereinigt wurden.

---

# Geplanter Löschablauf

```text
deleteAccount
    │
    ├── 1. Authentifizierung prüfen
    │
    ├── 2. sicherstellen, dass nur der eigene Account gelöscht wird
    │
    ├── 3. Admin-Sonderregel prüfen
    │
    ├── 4. accountStatus = deleting
    │
    ├── 5. erzeugte Notifications entfernen
    │
    ├── 6. Follower / Following bereinigen
    │
    ├── 7. Likes auf fremden Posts entfernen
    │
    ├── 8. Kommentare auf fremden Posts entfernen
    │
    ├── 9. Reports bereinigen / anonymisieren
    │
    ├── 10. eigene Posts inkl. Subcollections löschen
    │
    ├── 11. eigene User-Subcollections löschen
    │
    ├── 12. Profilbild löschen
    │
    ├── 13. Post-Bilder löschen
    │
    ├── 14. Admin-Dokument löschen
    │
    ├── 15. users/{uid} löschen
    │
    └── 16. Firebase-Authentication-Account löschen
```

---

# Implementierungsstrategie

Die Implementierung erfolgt schrittweise.

## Phase 1 – Sicherheitsgerüst

Zunächst wird eine Cloud Function `deleteAccount` erstellt, die noch keine Daten löscht.

Sie prüft ausschließlich:

* Ist ein Nutzer authentifiziert?
* Löscht der Nutzer ausschließlich seinen eigenen Account?
* Ist der Nutzer Admin?
* Ist er der letzte aktive Admin?
* Darf der Löschprozess gestartet werden?

## Phase 2 – Account sperren

```text
accountStatus: deleting
```

Während dieses Zustands dürfen keine normalen Benutzeraktionen mehr durchgeführt werden.

## Phase 3 – Datenbereinigung

Die einzelnen Datenbereiche werden schrittweise implementiert und jeweils mit Testaccounts überprüft.

## Phase 4 – Storage

Profil- und Post-Bilder werden entfernt.

## Phase 5 – endgültige Löschung

Zum Schluss werden das User-Dokument und anschließend der Firebase-Authentication-Account gelöscht.

## Phase 6 – Flutter UI

Erst nachdem der serverseitige Löschprozess zuverlässig funktioniert, wird die Accountlöschung mit dem Settings-Screen verbunden.

---

# Testfälle

Vor Veröffentlichung müssen mindestens folgende Fälle getestet werden:

* normaler Nutzer ohne Posts
* normaler Nutzer mit Posts
* Nutzer mit Kommentaren auf fremden Posts
* Nutzer mit Likes auf fremden Posts
* Nutzer mit Followers und Following
* Nutzer mit Notifications
* Nutzer mit FCM Tokens
* Nutzer mit ausgeblendeten Posts
* Nutzer mit Profilbild
* Nutzer mit Post-Bildern
* Nutzer, der Reports erstellt hat
* Nutzer, der selbst gemeldet wurde
* Admin bei mindestens zwei aktiven Admins
* letzter aktiver Admin
* teilweise fehlgeschlagene und anschließend erneut gestartete Löschung
