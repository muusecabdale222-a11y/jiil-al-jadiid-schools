# JIIL AL JADIID SCHOOLS — Hagaha dejinta

**App-kan waa bilow shaqayn kara oo ku xirmaya Supabase. Weli ma aha website online ah.** Si uu u noqdo nidaam toos ah, waa in la abuuro database-ka, lagu xiro app-ka, kadibna website-ka la daabaco.

## Waxa ku jira
- Login iyo password (Supabase Auth)
- Doorarka Admin, Teacher iyo Parent
- Diiwaanka ardayda iyo lambarka admission-ka
- Fasallo, maaddooyin iyo macallin fasal loo xilsaaro
- Xaadirin maalinle ah
- Imtixaanno iyo dhibco
- Diiwaanka lacagaha dugsiga
- Ogeysiisyada dugsiga
- Bogga waalidka oo muujinaya oo keliya carruurta akoonkiisa lala xiriiriyey
- Xeerarka RLS ee database-ka si loo xaddido cidda arki karta/bedeli karta xogta

## Tallaabada 1 — Samee Supabase Project
1. Fur https://supabase.com oo gal akoonkaaga.
2. Taabo **New project** (ama **Create a new project**).
3. Organization-ka dooro kii aad hadda samaysay.
4. Project name geli `JIIL AL JADIID SCHOOLS`.
5. Samee database password adag oo meel ammaan ah ku kaydi. Ha iigu soo dirin.
6. Region dooro mid kuu dhow haddii la heli karo, kadibna taabo **Create new project**.
7. Sug inta project-ku diyaar noqonayo.

## Tallaabada 2 — Samee database tables
1. Gudaha project-ka, fur **SQL Editor**.
2. Taabo **New query**.
3. Fur faylka `schema.sql` ee ZIP-kan, nuqul ka samee dhammaan qoraalka, kuna dheji SQL Editor.
4. Taabo **Run**. Haddii qalad kuu soo baxo, ha sii wadin; sawirka qaladka ii soo dir.

## Tallaabada 3 — Ku xidh app-ka Supabase
1. Gudaha Supabase fur **Project Settings → API** (mararka qaar waxaa lagu magacaabaa **API Keys**).
2. Nuqul ka samee **Project URL**.
3. Nuqul ka samee **anon/public** ama **publishable** key-ga.
4. Fur faylka `config.js` ee galka app-ka.
5. Ku beddel labada placeholder ee ku jira URL-ga iyo public key-gaaga.

**MUHIIM:** Waligaa ha gelin `service_role` ama `secret` key gudaha `config.js`, hana ku soo dirin chat. Public/anon key oo keliya ayaa loogu talagalay browser-ka, iyadoo RLS policies-ku shaqaynayaan.

## Tallaabada 4 — Samee Admin-ka koowaad
1. Marka app-ka la daabaco oo Supabase lagu xiro, fur app-ka.
2. Dooro **Create account** oo samee email, password, magaca iyo telefoonka Admin-ka koowaad.
3. Haddii email xaqiijin la dalbado, xaqiiji email-ka.
4. Supabase SQL Editor ku orod SQL-kan; ku beddel email-ka tusaalaha email-ka Admin-kaaga:

```sql
update public.profiles p
set role = 'admin'
from auth.users u
where p.id = u.id
  and lower(u.email) = lower('admin@dugsigaaga.com');
```

5. Ka bax app-ka, kadibna dib u gal. Hubi in doorka `ADMIN` muuqdo.

## Tallaabada 5 — Ku dar macallimiinta iyo waalidiinta
- Qofka cusub wuxuu marka hore samaysan karaa akoon Parent ah.
- Admin-ku wuxuu ka beddeli karaa doorka `Parent` una beddeli karaa `Teacher` ama `Admin` qaybta **Staff & Accounts**.
- Admin-ku wuxuu fasalka ku xiri karaa macallinka qaybta **Classes & Subjects**.
- Waalidka ku xidh ardaygiisa adigoo dooranaya **Linked parent account** marka ardayga la diiwaangelinayo ama la tafatirayo.

## Tallaabada 6 — Website-ka online geli
Waxaad u baahan tahay hosting sida Netlify ama Vercel. Ku shub galka mashruuca oo dhan, adigoo ilaalinaya qaabkan:

```text
jiil-al-jadiid-system/
  index.html
  config.js
  schema.sql
  SETUP.md
  assets/
    school-logo.jpg
```

Kadib Supabase **Authentication → URL Configuration** ku dar website URL-gaaga qaybta Site URL iyo Redirect URLs.

## Ka hor inta aan xog dhab ah la gelin
- Ku tijaabi akoon Admin, Teacher iyo Parent oo kala duwan.
- Hubi in waalidku arko carruurtiisa oo keliya.
- Hubi in macallinku arko fasallada isaga loo xilsaaray oo keliya.
- Hubi in natiijooyinka aan la daabicin aan waalidku arki karin.
- Samee backup iyo habka maamulka password-yada.
- Ha gelin xogta dhabta ah ee ardayda ilaa tijaabooyinkaas la dhammeeyo.

## Waxyaabaha aan wali ku jirin
SMS/WhatsApp toos ah, lacag-bixin online ah, soo dejinta Excel, report cards PDF, shaqo-guri online ah iyo casuumaad email oo uu server-ku maamulo. Kuwani waxay u baahan yihiin hawl horumarineed iyo adeegyo dheeraad ah.
