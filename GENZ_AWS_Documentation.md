# 📘 GENZ Studios — شرح كامل للـ AWS والكلاود

> **هذا الملف هو دليلك الشامل لفهم كيف يعمل تطبيق GENZ Studios مع خدمات Amazon Web Services (AWS)**
> مكتوب بأسلوب بسيط جداً — كأنك بتشرح لطفل صغير لأول مرة يسمع عن الكلاود

---

## الفهرس

| رقم | القسم |
|-----|-------|
| 1 | ما هو AWS Amplify وليه بنستخدمه؟ |
| 2 | خطوات إعداد الكلاود في التيرمينال خطوة بخطوة |
| 3 | الـ Schema — جدول البيانات في السحابة |
| 4 | الـ Authentication — نظام تسجيل الدخول (Cognito) |
| 5 | الـ API (AppSync + GraphQL) — كيف نبعت ونستقبل البيانات |
| 6 | الـ Storage (S3) — تخزين الصور |
| 7 | ملف main.dart — كيف يبدأ التطبيق |
| 8 | ملف aws_storage.dart — المحرك الأساسي |
| 9 | كيف تبعت البيانات (Mutations) |
| 10 | كيف تستقبل البيانات (Queries) |
| 11 | الـ Real-Time (Subscriptions) |
| 12 | نظام الإشعارات بالتفصيل |
| 13 | نظام الشات بالتفصيل |
| 14 | الـ Polling — البديل لما الـ Subscriptions مش شغالة |

---

---

## 1. 🌥️ ما هو AWS Amplify وليه بنستخدمه؟

### تخيل معايا القصة دي...

تخيل إنك عندك محل كبير (تطبيق GENZ Studios) وعندك زبائن بيجوا كل يوم. الزبون ده محتاج:

- **يسجل اسمه** عند الدخول (Authentication)
- **يحجز استوديو** ويحتفظ بالحجز (Database)
- **يرفع صورته** وصور الاستوديو (Storage)
- **يتكلم مع الموظف** في real-time (Chat)
- **يستلم إشعارات** لما حجزه يتقبل أو يترفض (Notifications)

لو هتعمل كل ده بنفسك — هتحتاج تشتري سيرفرات، تركبها، تحميها، وتدفع فلوس تانية على الكهربا والصيانة... ده صعب جداً وغالي!

**AWS (Amazon Web Services)** هو ببساطة: Amazon بتأجرك "كمبيوترات ضخمة في السحابة" وأنت بس بتدفع على اللي بتستخدمه. مفيش سيرفرات تشتريها، مفيش صيانة، مفيش ضغط.

### وما هو Amplify بالتحديد؟

**AWS Amplify** هو "مساعد ذكي" من Amazon بيسهّل عليك استخدام خدمات AWS في تطبيقك. بدل ما تكتب مئات الأسطر من الكود لتتصل بـ AWS — بتكتب أوامر بسيطة وهو بيعمل كل حاجة تلقائياً.

```
بدون Amplify:          مع Amplify:
───────────────        ───────────────
كود معقد جداً    →    أوامر بسيطة
إعداد يدوي        →    إعداد تلقائي
وقت طويل          →    دقائق معدودة
```

### ليه اخترنا Amplify لـ GENZ Studios؟

| السبب | التفسير |
|-------|---------|
| **سهولة الاستخدام** | أوامر بسيطة في التيرمينال تعمل كل حاجة |
| **Flutter Support** | يدعم Flutter بشكل ممتاز مع packages جاهزة |
| **Real-time** | يدعم subscriptions يعني بيانات مباشرة بدون refresh |
| **Authentication جاهز** | نظام تسجيل دخول كامل بدون ما تكتب حاجة |
| **مجاني في البداية** | Free tier يكفي للتطوير والاختبار |
| **Scalable** | لو طلب عليك كتير — AWS بيكبر معاك تلقائياً |

### الخدمات الرئيسية اللي بنستخدمها في GENZ

```
GENZ Studios App
│
├── 🔐 Amazon Cognito       → تسجيل الدخول والخروج
├── 📡 AWS AppSync          → الـ API (GraphQL)
├── 🗄️  Amazon DynamoDB     → قاعدة البيانات (خلف الكواليس)
├── 📦 Amazon S3            → تخزين الصور
└── ⚡ GraphQL Subscriptions → البيانات الحية (Real-time)
```

> **ملخص القسم الأول:**
> AWS = شركة Amazon بتأجرك كمبيوترات وخدمات في السحابة.
> Amplify = مساعد بيسهّل استخدام AWS في تطبيقك.
> GENZ Studios بيستخدم Cognito (دخول) + AppSync (API) + S3 (صور).

---

---

## 2. 💻 خطوات إعداد الكلاود في التيرمينال خطوة بخطوة

### ما هو التيرمينال؟

التيرمينال (أو Command Prompt أو PowerShell) هو النافذة السوداء اللي بتكتب فيها أوامر نصية. بدل ما تضغط بالماوس — بتكتب أوامر وهي بتنفذ.

### المتطلبات قبل ما تبدأ

قبل أي حاجة، لازم يكون عندك:

1. **Node.js** مثبّت على الجهاز (من nodejs.org)
2. **حساب AWS** (من aws.amazon.com — مجاني)
3. **Flutter** مثبّت
4. **VS Code** أو أي محرر كود

### الأوامر خطوة بخطوة

---

#### الخطوة 1: تثبيت Amplify CLI

```bash
npm install -g @aws-amplify/cli
```

**شرح سطر سطر:**
- `npm` = مدير الحزم لـ Node.js (زي متجر تطبيقات للكود)
- `install` = حمّل وثبّت
- `-g` = globally يعني على كل الجهاز مش بس في الفولدر الحالي
- `@aws-amplify/cli` = اسم الحزمة اللي عايز تثبتها

**ماذا يحدث؟** بتحمّل برنامج اسمه `amplify` على جهازك، وبعدها تقدر تكتب كلمة `amplify` في أي تيرمينال.

**للتأكد إنه اتثبت صح:**
```bash
amplify --version
# هيطلع مثلاً: 12.x.x
```

---

#### الخطوة 2: إعداد AWS Credentials

```bash
amplify configure
```

**شرح سطر سطر:**
- `amplify` = الأداة اللي حملتها في الخطوة السابقة
- `configure` = "اعدّ نفسك" يعني قوله بياناتك

**ماذا يحدث؟** هيفتح المتصفح تلقائياً وهيطلب منك:

```
1. تسجيل الدخول لحساب AWS الخاص بك
2. إنشاء مستخدم IAM جديد (IAM = Identity and Access Management)
3. إعطاء الأوامر صلاحيات للتعامل مع حسابك
```

**مثال على ما ستراه في التيرمينال:**
```
Specify the AWS Region: us-east-1
Specify the username of the new IAM user: genz-amplify-user
Complete the user creation using the AWS console...
Enter the access key of the newly created user:
accessKeyId: [تكتب هنا]
secretAccessKey: [تكتب هنا]
```

> **ملاحظة مهمة:** الـ Access Key و Secret Key هما كلمة سر حسابك على AWS. لا تشاركهمش مع أي حد ولا تحطهمش في الكود!

---

#### الخطوة 3: تهيئة المشروع

```bash
amplify init
```

**شرح:**
- `init` = initialize يعني "ابدأ من الأول"

**ماذا يحدث؟** هيسألك أسئلة عن مشروعك:

```
Enter a name for the project: genz
Enter a name for the environment: dev
Choose your default editor: Visual Studio Code
Choose the type of app that you're building: flutter
Where do you want to store your configuration file? ./lib/
```

**بعد ما تجاوب هيتعمل:**
```
amplify/
├── backend/          ← إعدادات الـ backend
├── .config/          ← إعدادات المشروع
└── team-provider-info.json
```

وفي Flutter هيتعمل ملف `amplifyconfiguration.dart` في `/lib/` وده أهم ملف — بيحتوي على كل عناوين الـ API والـ credentials.

---

#### الخطوة 4: إضافة Authentication

```bash
amplify add auth
```

**شرح:**
- `add` = أضف خدمة جديدة
- `auth` = Authentication (نظام التحقق من الهوية)

**ماذا يحدث؟** هيسألك:

```
Do you want to use the default authentication and security configuration?
▸ Default configuration
  Default configuration with Social Provider (Federation)
  Manual configuration
  I want to learn more.
```

في GENZ اخترنا الإعدادات دي:
```yaml
userPoolName: genz47b9027f_userpool_47b9027f
autoVerifiedAttributes: email      # بيبعت كود تأكيد على الإيميل
mfaConfiguration: OFF              # بدون Two-Factor Authentication
passwordPolicyMinLength: 8         # الباسورد 8 حروف على الأقل
usernameAttributes: email          # الدخول بالإيميل (مش يوزرنيم)
usernameCaseSensitive: false       # test@gmail.com = TEST@gmail.com
authSelections: identityPoolAndUserPool  # نوع خاص من الـ Auth
```

---

#### الخطوة 5: إضافة API

```bash
amplify add api
```

**شرح:**
- `api` = Application Programming Interface يعني "الطريق لتبادل البيانات"

**ماذا يحدث؟** هيسألك:

```
Select from one of the below mentioned services:
▸ GraphQL
  REST

Here is the GraphQL API that we will create. Select a setting to edit or continue:
▸ Name: genz
  Authorization modes: Amazon Cognito User Pool (default)
  Conflict detection (required for DataStore): Enabled
  Continue
```

في GENZ اخترنا:
- **GraphQL** (بدل REST) — لأنه أسرع وأكفأ
- **Conflict Detection: Enabled** — عشان لو حد عدّل بيانات في نفس الوقت، نحل التعارض
- **Authorization: Cognito** — بس الناس المسجلين يقدروا يوصلوا البيانات

---

#### الخطوة 6: إضافة Storage

```bash
amplify add storage
```

**شرح:**
- `storage` = تخزين الملفات والصور

**ماذا يحدث؟** هيسألك:

```
Select from one of the below mentioned services:
▸ Content (Images, audio, video, etc.)
  NoSQL Database

Who should have access:
▸ Auth users only
  Auth and Guest users

What kind of access do you want for Authenticated users?
▸ create/update, read, delete
```

في GENZ: بس المستخدمين المسجلين يقدروا يرفعوا صور.

---

#### الخطوة 7: رفع التغييرات للسحابة

```bash
amplify push
```

**شرح:**
- `push` = "ادفع" يعني ارفع كل الإعدادات اللي عملتها لـ AWS

**ماذا يحدث؟** ده أهم أمر! هيعمل التالي:

```
✅ إنشاء User Pool في Cognito
✅ إنشاء GraphQL API في AppSync
✅ إنشاء جداول في DynamoDB
✅ إنشاء Bucket في S3
✅ ربط كل الخدمات ببعض
```

هيسألك:
```
Do you want to generate code for your newly created GraphQL API? Yes
Choose the code generation language target: dart
Enter the file name pattern of graphql queries...: lib/graphql/**/*.graphql
Do you want to generate/update all possible GraphQL operations?: Yes
```

**ده بياخد وقت** (5-15 دقيقة) عشان AWS بيبني كل حاجة في السحابة.

---

#### الخطوة 8: توليد الـ Dart Models

```bash
amplify codegen models
```

**شرح:**
- `codegen` = code generation يعني "ولّد كود تلقائياً"
- `models` = النماذج (الـ classes في Dart)

**ماذا يحدث؟** هيقرأ الـ Schema (اللي هنشرحه بعدين) ويولّد ملفات Dart تلقائياً:

```
lib/models/
├── Studio.dart
├── BookingRequest.dart
├── ChatMessage.dart
├── AppNotification.dart
├── UserProfile.dart
└── ModelProvider.dart
```

ده بيوفر عليك ساعات من الكتابة! بدل ما تكتب الـ classes بإيدك، Amplify بيكتبها تلقائياً من الـ Schema.

---

#### الخطوة 9: فتح الـ AppSync Console

```bash
amplify console api
```

**شرح:**
- `console` = افتح لوحة التحكم في المتصفح
- `api` = للـ API تحديداً

**ماذا يحدث؟** هيفتح المتصفح مباشرة على صفحة AppSync في AWS حيث تقدر:
- تشوف جداول البيانات
- تجرب الـ GraphQL Queries يدوياً
- تشوف الـ Subscriptions

---

#### الخطوة 10: عرض حالة المشروع

```bash
amplify status
```

**شرح:**
- `status` = "ما هو الوضع الحالي؟"

**مثال على الناتج:**

```
Current Environment: dev

| Category | Resource name          | Operation | Provider plugin   |
| -------- | ---------------------- | --------- | ----------------- |
| Auth     | genz47b9027f           | No Change | awscloudformation |
| Api      | genz                   | No Change | awscloudformation |
| Storage  | s3bucket               | No Change | awscloudformation |
```

> **ملخص القسم الثاني:**
> الأوامر دي بتبني البنية التحتية الكاملة لتطبيقك في AWS.
> الترتيب مهم: configure → init → add auth → add api → add storage → push → codegen models.
> `amplify push` هو الأمر الأهم — هو اللي بيرفع كل حاجة للسحابة فعلاً.

---

---

## 3. 🗄️ الـ Schema — جدول البيانات في السحابة

### ما هو الـ Schema؟

تخيل إنك عندك دفتر لتسجيل حجوزات الاستوديو. الـ Schema هو "قالب الدفتر" — بيحدد:
- إيه الأعمدة الموجودة (الحقول)
- نوع كل عمود (نص، رقم، صواب/خطأ)
- هل الحقل إجباري أم اختياري

في GENZ، الـ Schema محفوظ في:
```
amplify/backend/api/genz/schema.graphql
```

### شرح GraphQL Schema

**GraphQL** هي لغة بتستخدمها لوصف شكل البيانات. زي ما Excel عنده أنواع بيانات (نص، رقم، تاريخ) — GraphQL بيعمل نفس الحاجة بس للـ API.

### جداول البيانات في GENZ (النماذج الـ 5)

---

#### 📋 الجدول الأول: Studio (الاستوديو)

```graphql
type Studio @model @auth(rules: [{ allow: private }]) {
  id: ID!
  name: String!
  type: String!
  pricePerHour: Int!
  description: String
  image: String
  available: Boolean
}
```

**شرح كل سطر:**

| السطر | المعنى |
|-------|--------|
| `type Studio` | اسم الجدول هو "Studio" |
| `@model` | كلمة سحرية تقول لـ Amplify "اعمل جدول في DynamoDB لده" |
| `@auth(rules: [{ allow: private }])` | بس الناس المسجلين (private) يقدروا يشوفوا البيانات |
| `id: ID!` | كل استوديو له ID فريد — الـ ! معناها "إجباري" |
| `name: String!` | اسم الاستوديو — نص إجباري |
| `type: String!` | نوع الاستوديو (تسجيل صوتي، تصوير...) — إجباري |
| `pricePerHour: Int!` | السعر بالساعة — رقم صحيح إجباري |
| `description: String` | وصف الاستوديو — اختياري (بدون !) |
| `image: String` | رابط الصورة في S3 — اختياري |
| `available: Boolean` | هل متاح؟ true أو false |

**مثال على البيانات:**
```json
{
  "id": "studio-001",
  "name": "استوديو النجوم",
  "type": "تسجيل صوتي",
  "pricePerHour": 150,
  "description": "استوديو مجهز بالكامل",
  "image": "s3://genz-bucket/studios/studio-001.jpg",
  "available": true
}
```

---

#### 📅 الجدول الثاني: BookingRequest (طلب الحجز)

```graphql
type BookingRequest @model @auth(rules: [{ allow: private }]) {
  id: ID!
  clientEmail: String! @index(name: "byClientEmail", queryField: "bookingRequestsByClientEmail")
  clientName: String
  clientPhone: String
  studio: String!
  date: String!
  hours: String!
  price: String!
  equipment: String
  status: String
  fullStartDateTime: String! @index(name: "byStartDate", queryField: "bookingRequestsByStart")
  fullEndDateTime: String!
}
```

**شرح كل سطر:**

| الحقل | النوع | المعنى |
|-------|-------|--------|
| `id` | ID | رقم فريد لكل حجز |
| `clientEmail` | String! | إيميل العميل — إجباري |
| `clientName` | String | اسم العميل — اختياري |
| `clientPhone` | String | تليفون العميل — اختياري |
| `studio` | String! | اسم الاستوديو المحجوز — إجباري |
| `date` | String! | تاريخ الحجز — إجباري |
| `hours` | String! | عدد الساعات المحجوزة — إجباري |
| `price` | String! | السعر الإجمالي — إجباري |
| `equipment` | String | معدات إضافية مطلوبة — اختياري |
| `status` | String | حالة الحجز: Pending/Approved/Rejected |
| `fullStartDateTime` | String! | وقت البداية الكامل — إجباري |
| `fullEndDateTime` | String! | وقت النهاية الكامل — إجباري |

**ما هو `@index`؟**

```graphql
clientEmail: String! @index(name: "byClientEmail", queryField: "bookingRequestsByClientEmail")
```

الـ `@index` بيعمل "فهرس" على الحقل ده. تخيل كتاب فيه فهرس في الآخر — بدل ما تقلب كل الصفحات لتلاقي موضوع، بتبص في الفهرس مباشرة.

- `name: "byClientEmail"` = اسم الفهرس
- `queryField: "bookingRequestsByClientEmail"` = اسم الـ query اللي تقدر تستخدمه في الكود

**يعني بدل ما تجيب كل الحجوزات وتفلترها في الكود — بتطلب من AWS مباشرة "هاتلي حجوزات العميل ده بس."**

---

#### 💬 الجدول الثالث: ChatMessage (رسالة الشات)

```graphql
type ChatMessage @model @auth(rules: [{ allow: private }]) {
  id: ID!
  senderName: String
  senderEmail: String
  clientEmail: String! @index(name: "byClientEmail", queryField: "chatMessagesByClientEmail")
  text: String
  time: String
  messageType: String
  parentId: String @index(name: "byParent", queryField: "chatMessagesByParent")
}
```

**شرح الحقول:**

| الحقل | المعنى |
|-------|--------|
| `senderName` | اسم اللي بعت الرسالة |
| `senderEmail` | إيميل المُرسل |
| `clientEmail` | إيميل العميل المرتبط بالمحادثة (مش بالضرورة المُرسل) |
| `text` | نص الرسالة |
| `time` | وقت الإرسال |
| `messageType` | نوع الرسالة: "text"، "image"، "system" |
| `parentId` | لو الرسالة رد على رسالة تانية — ID الرسالة الأصلية |

**لماذا `clientEmail` مش `senderEmail` للفهرس؟**

لأن المحادثة دايماً بين عميل واحد وكل الموظفين. فبنفهرس على `clientEmail` عشان نجيب كل رسائل محادثة عميل معين بسرعة.

---

#### 🔔 الجدول الرابع: AppNotification (الإشعار)

```graphql
type AppNotification @model @auth(rules: [{ allow: private }]) {
  id: ID!
  clientEmail: String! @index(name: "byClientEmail", queryField: "appNotificationsByClientEmail")
  title: String
  body: String
  type: String
  time: String
  read: Boolean
}
```

**شرح الحقول:**

| الحقل | المعنى | مثال |
|-------|--------|------|
| `clientEmail` | مين المفروض يستقبل الإشعار | `ahmed@gmail.com` |
| `title` | عنوان الإشعار | "تم قبول حجزك!" |
| `body` | نص الإشعار | "تم تأكيد حجز استوديو النجوم..." |
| `type` | نوع الإشعار | "Approved", "Rejected", "Pending", "chat_opened" |
| `time` | وقت الإشعار | "2024-01-15T10:30:00Z" |
| `read` | هل قراه العميل؟ | true / false |

---

#### 👤 الجدول الخامس: UserProfile (ملف المستخدم)

```graphql
type UserProfile @model @auth(rules: [{ allow: private }]) {
  id: ID!
  email: String! @index(name: "byEmail", queryField: "userProfilesByEmail")
  name: String
  image: String
  type: String
  chatEnabled: Boolean
  lastUpdated: AWSDateTime
}
```

**شرح الحقول:**

| الحقل | المعنى | مثال |
|-------|--------|------|
| `email` | إيميل المستخدم | `ahmed@gmail.com` |
| `name` | الاسم الكامل | "Ahmed Mohamed" |
| `image` | صورة الملف الشخصي | رابط S3 |
| `type` | نوع المستخدم | "client" أو "employee" |
| `chatEnabled` | هل الشات مفتوح لهذا العميل؟ | true / false |
| `lastUpdated` | آخر تعديل | `AWSDateTime` نوع خاص بـ AWS |

**ملاحظة على `AWSDateTime`:** ده نوع بيانات خاص بـ AWS AppSync بيحفظ التاريخ والوقت بتنسيق ISO 8601 (مثلاً: `2024-01-15T10:30:00.000Z`).

### الحقول التلقائية اللي بيضيفها Amplify

لما بتعمل `@model`، Amplify بيضيف حقول إضافية تلقائياً لكل جدول:

```graphql
_version: Int!        # رقم الإصدار (للـ conflict detection)
_deleted: Boolean     # هل الـ record اتحذف؟ (soft delete)
_lastChangedAt: AWSTimestamp!  # آخر تعديل
createdAt: AWSDateTime!        # تاريخ الإنشاء
updatedAt: AWSDateTime!        # تاريخ آخر تعديل
```

**أهمهم: `_version`** — هنشرحه بالتفصيل في قسم الـ Mutations.

> **ملخص القسم الثالث:**
> الـ Schema هو "خريطة البيانات" — بيحدد شكل كل جدول وحقوله.
> الـ @model بيعمل جدول في DynamoDB تلقائياً.
> الـ @index بيعمل فهرس للبحث السريع على حقل معين.
> عندنا 5 جداول: Studio, BookingRequest, ChatMessage, AppNotification, UserProfile.

---

---

## 4. 🔐 الـ Authentication — نظام تسجيل الدخول (Cognito)

### ما هو Cognito؟

تخيل الكونسيرج في الفندق — اللي بيسألك "مين حضرتك؟" قبل ما تدخل. **Amazon Cognito** هو نظام التحقق من الهوية في AWS.

بيعمل:
- تسجيل حسابات جديدة (Sign Up)
- تسجيل الدخول (Sign In)
- تسجيل الخروج (Sign Out)
- تأكيد الإيميل (Email Verification)
- استعادة الباسورد (Forgot Password)

### إعدادات Cognito في GENZ

```yaml
userPoolName: genz47b9027f_userpool_47b9027f
autoVerifiedAttributes: email
mfaConfiguration: OFF
passwordPolicyMinLength: 8
usernameAttributes: email
usernameCaseSensitive: false
authSelections: identityPoolAndUserPool
```

**شرح كل إعداد:**

---

#### `userPoolName: genz47b9027f_userpool_47b9027f`

**ما هو User Pool؟**
تخيله كدفتر أسماء — فيه كل حسابات مستخدمي التطبيق.
- `genz` = اسم المشروع
- `47b9027f` = رقم عشوائي أضافه Amplify عشان يضمن الاسم فريد
- `_userpool_` = ده User Pool
- كل مشروع Amplify له User Pool خاص بيه

---

#### `autoVerifiedAttributes: email`

**معناه:** لما حد يسجل حساب جديد، Amplify بيبعتله إيميل فيه كود تأكيد. لازم يكتب الكود عشان يكمل التسجيل.

```
المستخدم يكتب إيميله وباسورده
        ↓
Cognito يبعت إيميل بكود (مثلاً: 847293)
        ↓
المستخدم يكتب الكود في التطبيق
        ↓
الحساب يتفعّل
```

ليه ده مهم؟ عشان نتأكد إن الإيميل حقيقي وبتاع المستخدم فعلاً.

---

#### `mfaConfiguration: OFF`

**MFA = Multi-Factor Authentication** (التحقق بخطوتين — زي ما بيعمل البنك)

في GENZ: OFF يعني مطلوبش. المستخدم بيدخل إيميل + باسورد بس.

لو كانت ON: كان هيبعت كود SMS كمان (أمان أكتر بس أصعب على المستخدمين).

---

#### `passwordPolicyMinLength: 8`

الباسورد لازم يكون 8 حروف على الأقل. Cognito بيرفض الباسورد لو أقصر من كده.

يمكن تضيف شروط تانية زي:
```
requireUppercase: true    # لازم فيه حرف كبير
requireNumbers: true      # لازم فيه رقم
requireSymbols: true      # لازم فيه رمز (!@#$)
```

---

#### `usernameAttributes: email`

يعني المستخدم بيسجل الدخول بـ **الإيميل** مش بـ username منفصل.

```
بدل ما:   username: ahmed123
          password: xxxxxxxx

بيكون:    email: ahmed@gmail.com
          password: xxxxxxxx
```

أسهل للمستخدم عشان الإيميل بيتذكره دايماً.

---

#### `usernameCaseSensitive: false`

يعني مفيش فرق بين الحروف الكبيرة والصغيرة في الإيميل:
```
Ahmed@Gmail.com = ahmed@gmail.com = AHMED@GMAIL.COM
```

---

#### `authSelections: identityPoolAndUserPool`

ده إعداد متقدم شوية:

| المصطلح | المعنى |
|---------|--------|
| **User Pool** | بيتحكم في "مين مسموح يدخل التطبيق" |
| **Identity Pool** | بيدي كل مستخدم صلاحيات مؤقتة للـ AWS services (زي S3) |

بالتالي:
- User Pool = "هل هذا المستخدم موجود في نظامنا؟"
- Identity Pool = "ما هي صلاحياته في AWS؟"

---

### كيف يبدو تسجيل الدخول في الكود

```dart
// تسجيل الدخول
Future<void> signIn(String email, String password) async {
  try {
    final result = await Amplify.Auth.signIn(
      username: email,
      password: password,
    );
    if (result.isSignedIn) {
      print('تم تسجيل الدخول بنجاح!');
    }
  } on AuthException catch (e) {
    print('خطأ: ${e.message}');
  }
}
```

```dart
// التسجيل الجديد
Future<void> signUp(String email, String password) async {
  await Amplify.Auth.signUp(
    username: email,
    password: password,
    options: SignUpOptions(
      userAttributes: {
        AuthUserAttributeKey.email: email,
      },
    ),
  );
}
```

```dart
// تأكيد الإيميل
Future<void> confirmSignUp(String email, String code) async {
  await Amplify.Auth.confirmSignUp(
    username: email,
    confirmationCode: code,
  );
}
```

### كيف يتحقق الكود إن المستخدم مسجل دخوله

في ملف `aws_storage.dart` في GENZ، عندنا دالة مهمة:

```dart
// requireSignedIn — بيتحقق إن المستخدم مسجل دخوله قبل أي عملية
static Future<void> requireSignedIn() async {
  final session = await Amplify.Auth.fetchAuthSession();
  if (!session.isSignedIn) {
    throw Exception('المستخدم غير مسجل الدخول');
  }
}
```

**كل عملية في التطبيق بتبدأ بـ `requireSignedIn()`** — زي الحارس على الباب.

> **ملخص القسم الرابع:**
> Cognito هو نظام تسجيل الدخول في AWS.
> في GENZ: الدخول بالإيميل، باسورد 8 أحرف، تأكيد الإيميل إجباري.
> User Pool للمستخدمين، Identity Pool للصلاحيات.

---

---

## 5. 📡 الـ API (AppSync + GraphQL) — كيف نبعت ونستقبل البيانات

### ما هو الـ API؟

تخيل الـ API كـ "نادل في مطعم":
- أنت (التطبيق) بتطلب أكلة (بيانات)
- النادل (API) بيروح للمطبخ (قاعدة البيانات)
- ويرجع بالأكلة (البيانات) ليك

### ما هو AWS AppSync؟

**AppSync** هو خدمة AWS خاصة بالـ GraphQL APIs. بيعمل:
- استقبال طلبات البيانات
- التحقق من الهوية (مع Cognito)
- التواصل مع قاعدة البيانات (DynamoDB)
- إرجاع البيانات للتطبيق
- دعم Real-time (Subscriptions)

### ما هو GraphQL؟

**GraphQL** هي لغة لطلب البيانات. بدل ما تطلب "هاتلي كل بيانات المستخدم"، بتقول بالضبط "هاتلي الاسم والإيميل بس."

**REST API (القديم):**
```
GET /users/123
→ يرجع كل البيانات حتى اللي مش محتاجها
{id, name, email, phone, address, createdAt, updatedAt, ...}
```

**GraphQL (الحديث):**
```graphql
query {
  getUser(id: "123") {
    name
    email
  }
}
→ يرجع بس اللي طلبته
{name: "Ahmed", email: "ahmed@gmail.com"}
```

**أسرع وأكفأ** لأن بياخد بيانات أقل من النت.

### أنواع العمليات في GraphQL

```
GraphQL Operations
│
├── Query      → قراءة البيانات (زي SELECT في SQL)
├── Mutation   → كتابة/تعديل/حذف البيانات (INSERT/UPDATE/DELETE)
└── Subscription → استقبال البيانات بشكل حي (Real-time)
```

### كيف Amplify بيولّد الـ API تلقائياً

لما بتعمل `amplify push`، AppSync بيولّد تلقائياً كل الـ Operations دي لكل جدول:

**للـ Studio مثلاً:**

```graphql
# Queries (قراءة)
getStudio(id: ID!): Studio
listStudios(filter: ...): StudioConnection

# Mutations (كتابة)
createStudio(input: CreateStudioInput!): Studio
updateStudio(input: UpdateStudioInput!): Studio
deleteStudio(input: DeleteStudioInput!): Studio

# Subscriptions (حي)
onCreateStudio: Studio
onUpdateStudio: Studio
onDeleteStudio: Studio
```

كل ده بدون ما تكتب سطر كود!

### كيف بنستخدم الـ API في Flutter

في Flutter، Amplify بيوفر package اسمها `amplify_api` بتسهّل الكلام مع AppSync.

**طريقتين للاستخدام:**

#### الطريقة 1: Model-based (الأسهل)

```dart
// إنشاء Studio جديد
final studio = Studio(
  name: "استوديو النجوم",
  type: "تسجيل صوتي",
  pricePerHour: 150,
);

final response = await Amplify.API
  .mutate(request: ModelMutations.create(studio))
  .response;
```

Amplify بيبني الـ GraphQL query تلقائياً من الـ model.

#### الطريقة 2: Raw GraphQL (للحالات المعقدة)

```dart
const query = '''
  query GetStudio($id: ID!) {
    getStudio(id: $id) {
      id name type pricePerHour
    }
  }
''';

final response = await Amplify.API.query(
  request: GraphQLRequest<String>(
    document: query,
    variables: {'id': 'studio-001'},
  ),
).response;
```

> **ملخص القسم الخامس:**
> AppSync = خدمة AWS للـ GraphQL API.
> GraphQL = طريقة حديثة لطلب البيانات — بتطلب بس اللي محتاجه.
> 3 أنواع عمليات: Query (قراءة), Mutation (كتابة), Subscription (حي).

---

---

## 6. 📦 الـ Storage (S3) — تخزين الصور

### ما هو Amazon S3؟

**S3 = Simple Storage Service** — تخيله كـ "USB ضخم في السحابة" تقدر ترفع عليه أي ملف وتقدر توصله من أي مكان في العالم.

في GENZ بنستخدمه لـ:
- صور الاستوديوهات
- صور المستخدمين (Profile pictures)

### الـ Bucket

الـ **Bucket** في S3 هو "الفولدر الرئيسي". زي hard drive كاملة بتأجرها.

```
S3 Bucket: genz-storage-bucket
│
├── public/
│   └── studios/
│       ├── studio-001.jpg
│       └── studio-002.jpg
│
└── private/
    └── users/
        ├── ahmed@gmail.com/profile.jpg
        └── sara@gmail.com/profile.jpg
```

### رفع صورة على S3 في Flutter

```dart
// رفع صورة استوديو
static Future<String?> uploadStudioImage(File imageFile, String studioId) async {
  try {
    await requireSignedIn();
    
    final key = 'studios/$studioId.jpg';  // المسار في S3
    
    final result = await Amplify.Storage.uploadFile(
      localFile: AWSFile.fromPath(imageFile.path),
      key: key,
      options: const StorageUploadFileOptions(
        accessLevel: StorageAccessLevel.guest,  // عام — الكل يشوفه
      ),
    ).result;
    
    return result.uploadedItem.key;  // بيرجع المسار
    
  } catch (e) {
    safePrint('خطأ في الرفع: $e');
    return null;
  }
}
```

### الحصول على URL الصورة

```dart
// جلب URL صورة الاستوديو
static Future<String?> getStudioImageUrl(String key) async {
  try {
    final result = await Amplify.Storage.getUrl(
      key: key,
      options: const StorageGetUrlOptions(
        accessLevel: StorageAccessLevel.guest,
        pluginOptions: S3GetUrlPluginOptions(
          expiresIn: Duration(hours: 1),  // الرابط صالح ساعة
        ),
      ),
    ).result;
    
    return result.url.toString();
  } catch (e) {
    return null;
  }
}
```

### مستويات الوصول في S3

```
StorageAccessLevel
│
├── guest    → الكل يشوفه (حتى بدون دخول)  ← للصور العامة
├── protected → بس المستخدم المسجل يشوفه    ← للصور الشخصية
└── private  → بس صاحبه يشوفه              ← للملفات الخاصة جداً
```

في GENZ:
- صور الاستوديوهات: `guest` (الكل يشوفها)
- صور المستخدمين: `protected`

> **ملخص القسم السادس:**
> S3 = تخزين الملفات والصور في السحابة.
> Bucket = الفولدر الرئيسي في S3.
> 3 مستويات وصول: guest (عام), protected, private.

---

---

## 7. 🚀 ملف main.dart — كيف يبدأ التطبيق

### ما هو main.dart؟

`main.dart` هو "أول ما يشتغل" في أي تطبيق Flutter. زي "مفتاح التشغيل" — لما المستخدم يفتح التطبيق، أول كود بيتنفذ هو اللي في `main.dart`.

### كيف Amplify بيبدأ في التطبيق

```dart
Future<void> _configureAmplify() async {
  final List<AmplifyPluginInterface> plugins = [
    AmplifyAPI(
      options: APIPluginOptions(modelProvider: ModelProvider.instance),
    ),
    AmplifyAuthCognito(),
    AmplifyStorageS3(),
  ];
  await Amplify.addPlugins(plugins);
  await Amplify.configure(amplifyconfig);
}
```

**شرح كل سطر:**

---

#### `Future<void> _configureAmplify() async`

```
Future<void>  = الدالة دي بتاخد "وقت" عشان تشتغل (async)
              = void تعني مش بترجع قيمة
_configureAmplify = اسم الدالة (الـ _ تعني private)
async         = هتستخدم await جوا
```

---

#### `final List<AmplifyPluginInterface> plugins = [...]`

بنعمل قايمة (List) من الـ Plugins (الإضافات). كل plugin بيضيف قدرة لـ Amplify.

---

#### `AmplifyAPI(options: APIPluginOptions(modelProvider: ModelProvider.instance))`

```
AmplifyAPI          = الإضافة اللي بتربطنا بـ AppSync
APIPluginOptions    = إعدادات الإضافة
modelProvider       = بيقول لـ Amplify "اعرف الـ models بتاعتنا"
ModelProvider.instance = بيجيب قايمة كل الـ models (Studio, BookingRequest, ...)
```

**لماذا ModelProvider مهم؟**

بدونه، Amplify مش هيعرف إزاي يحوّل البيانات الجاية من AppSync لـ Dart objects. يعني بدله مش هتقدر تكتب:
```dart
final studio = response.data;  // هيكون null!
```

---

#### `AmplifyAuthCognito()`

```
AmplifyAuthCognito = الإضافة اللي بتربطنا بـ Cognito
                   = تسجيل الدخول والخروج
                   = بدونها: مش هتقدر تسجل دخول
```

---

#### `AmplifyStorageS3()`

```
AmplifyStorageS3  = الإضافة اللي بتربطنا بـ S3
                  = رفع وتحميل الملفات والصور
                  = بدونها: مش هتقدر ترفع صور
```

---

#### `await Amplify.addPlugins(plugins)`

```
addPlugins = "أضف هذه الإضافات لـ Amplify"
           = بيسجّل كل plugin
           = لازم تتنفذ قبل configure
```

---

#### `await Amplify.configure(amplifyconfig)`

```
configure      = "اعدّ نفسك بهذه المعلومات"
amplifyconfig  = ملف الإعدادات المولّد تلقائياً
               = موجود في lib/amplifyconfiguration.dart
               = بيحتوي على عناوين الـ API والـ Keys
```

### ملف amplifyconfiguration.dart

هذا الملف بيتولّد تلقائياً بعد `amplify push`. مثاله:

```dart
const amplifyconfig = '''{
    "UserAgent": "aws-amplify-cli/2.0",
    "Version": "1.0",
    "api": {
        "plugins": {
            "awsAPIPlugin": {
                "genz": {
                    "endpointType": "GraphQL",
                    "endpoint": "https://xxxxxxxxxx.appsync-api.us-east-1.amazonaws.com/graphql",
                    "region": "us-east-1",
                    "authorizationType": "AMAZON_COGNITO_USER_POOLS"
                }
            }
        }
    },
    "auth": {
        "plugins": {
            "awsCognitoAuthPlugin": {
                "UserAgent": "aws-amplify-cli/0.1.0",
                "Version": "0.1.0",
                "IdentityManager": { "Default": {} },
                "CognitoUserPool": {
                    "Default": {
                        "PoolId": "us-east-1_XXXXXXXXX",
                        "AppClientId": "XXXXXXXXXXXXXXXXXXXXXXXXXX",
                        "Region": "us-east-1"
                    }
                }
            }
        }
    },
    "storage": {
        "plugins": {
            "awsS3StoragePlugin": {
                "bucket": "genz-storage-bucket",
                "region": "us-east-1",
                "defaultAccessLevel": "guest"
            }
        }
    }
}''';
```

### الترتيب الكامل لبداية التطبيق

```dart
void main() async {
  // 1. تأكد إن Flutter جاهز
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. إعداد Amplify
  await _configureAmplify();
  
  // 3. تشغيل التطبيق
  runApp(MyApp());
}
```

**لماذا هذا الترتيب مهم؟**

```
WidgetsFlutterBinding.ensureInitialized()
    ↓
يجهّز محرك Flutter للعمل مع async code
    ↓
_configureAmplify()
    ↓
يربط التطبيق بـ AWS (Cognito + AppSync + S3)
    ↓
runApp(MyApp())
    ↓
يشغّل الواجهة — دلوقتي البيانات جاهزة
```

لو شغّلت `runApp` قبل `configureAmplify` — هيحصل خطأ لأن الـ API مش متجهز بعد.

> **ملخص القسم السابع:**
> main.dart هو أول كود يشتغل في التطبيق.
> `_configureAmplify()` بتضيف 3 plugins: API + Auth + Storage.
> `amplifyconfig` هو ملف الإعدادات المولّد تلقائياً من Amplify.
> الترتيب: Initialize Flutter → Configure Amplify → Run App.

---

---

## 8. ⚙️ ملف aws_storage.dart — المحرك الأساسي

### ما هو aws_storage.dart؟

هو ملف Dart مركزي في مشروع GENZ — بيحتوي على **كل** العمليات اللي بنتعامل بيها مع AWS.

تخيله كـ "مدير الخدمات" — أي شاشة في التطبيق عايزة بيانات، بتكلّم الملف ده.

```
أي Screen في التطبيق
        ↓
  AWSStorageService (aws_storage.dart)
        ↓
  AWS AppSync / S3 / Cognito
        ↓
  البيانات ترجع للـ Screen
```

### الهيكل العام للملف

```dart
class AWSStorageService {
  // ═══════════════════════════════
  // Helper Functions
  // ═══════════════════════════════
  static Future<void> requireSignedIn() async { ... }
  
  // ═══════════════════════════════
  // Studio Operations
  // ═══════════════════════════════
  static Future<List<Studio>> getStudios() async { ... }
  static Future<bool> createStudio(Studio studio) async { ... }
  
  // ═══════════════════════════════
  // Booking Operations
  // ═══════════════════════════════
  static Future<bool> createBooking(BookingRequest booking) async { ... }
  static Future<List<BookingRequest>> getBookings() async { ... }
  static Future<bool> updateBookingStatus(String id, String status) async { ... }
  
  // ═══════════════════════════════
  // Notification Operations
  // ═══════════════════════════════
  static Future<bool> sendNotification({...}) async { ... }
  static Future<List<AppNotification>> getNotifications(String email) async { ... }
  
  // ═══════════════════════════════
  // Chat Operations
  // ═══════════════════════════════
  static Future<bool> sendMessage({...}) async { ... }
  static Stream<ChatMessage> subscribeToChatMessages({...}) { ... }
  
  // ═══════════════════════════════
  // UserProfile Operations
  // ═══════════════════════════════
  static Future<UserProfile?> getUserProfile(String email) async { ... }
  static Future<bool> setChatEnabled(String email, bool enable) async { ... }
  static Future<bool> isChatEnabled(String email) async { ... }
}
```

### لماذا كل الدوال `static`؟

الكلمة `static` تعني إنك مش محتاج تعمل object من الـ class عشان تستخدمها:

```dart
// بدون static - محتاج تعمل object
final service = AWSStorageService();
await service.sendNotification(...);

// مع static - بتكلمها مباشرة
await AWSStorageService.sendNotification(...);
```

في GENZ اخترنا `static` عشان:
1. أسهل في الاستخدام
2. مفيش حاجة تخزّنها في الـ object
3. كل الشاشات بتشاركها بشكل أبسط

> **ملخص القسم الثامن:**
> aws_storage.dart هو المحرك المركزي — كل عمليات AWS بتمر بيه.
> كل الدوال static عشان سهولة الاستخدام من أي مكان في التطبيق.

---

---

## 9. ✍️ كيف تبعت البيانات (Mutations)

### ما هي الـ Mutation؟

**Mutation** بالعربي تعني "تغيير" أو "طفرة" — وفي GraphQL بتعني "أي عملية بتغيّر البيانات":
- إنشاء بيانات جديدة (Create)
- تعديل بيانات موجودة (Update)
- حذف بيانات (Delete)

### مثال 1: إرسال إشعار (Create Mutation)

```dart
// إرسال إشعار
static Future<bool> sendNotification({
  required String clientEmail,
  required String title,
  required String body,
  String type = 'info',
}) async {
  await requireSignedIn();
  final notif = AppNotification(
    clientEmail: clientEmail,
    title: title,
    body: body,
    type: type,
    time: DateTime.now().toUtc().toIso8601String(),
    read: false,
  );
  final response = await Amplify.API
      .mutate(request: ModelMutations.create(notif))
      .response;
  return response.errors.isEmpty;
}
```

**شرح سطر سطر:**

---

**السطر:** `static Future<bool> sendNotification({...}) async`

```
static       = تقدر تستدعيها بدون object
Future<bool> = بترجع true (نجح) أو false (فشل) بعد انتظار
required     = الباراميتر ده إجباري
String type = 'info' = القيمة الافتراضية 'info' لو مش حدد
```

---

**السطر:** `await requireSignedIn()`

```
قبل أي عملية، تأكد إن المستخدم مسجل دخوله.
لو مش مسجل — بيرمي Exception وبتوقف هنا.
```

---

**السطر:** `final notif = AppNotification(...)`

```
بنعمل object من نوع AppNotification
هذا الـ class اتولّد تلقائياً من amplify codegen models
```

---

**السطر:** `time: DateTime.now().toUtc().toIso8601String()`

```
DateTime.now()           = الوقت الحالي على الجهاز
.toUtc()                 = حوّله لـ UTC (وقت عالمي موحّد)
.toIso8601String()       = حوّله لنص: "2024-01-15T10:30:00.000Z"
```

لماذا UTC؟ عشان لو في عميل في مصر وموظف في دبي — الوقت هيتحسب صح للاتنين.

---

**السطر:** `final response = await Amplify.API.mutate(request: ModelMutations.create(notif)).response`

```
Amplify.API          = الـ API plugin
.mutate(...)         = عملية mutation (تغيير في البيانات)
ModelMutations.create(notif) = "اعمل insert لهذا الـ object في DynamoDB"
.response            = انتظر الرد من السيرفر
```

**ما الذي يحدث خلف الكواليس؟**

```
Dart Code
    ↓
Amplify Library بيبني GraphQL Mutation تلقائياً:
mutation CreateAppNotification($input: CreateAppNotificationInput!) {
  createAppNotification(input: $input) {
    id clientEmail title body type time read _version
  }
}
    ↓
بيبعته لـ AWS AppSync
    ↓
AppSync بيكتبه في DynamoDB
    ↓
بيرجع الـ object المنشأ مع الـ id الجديد
```

---

**السطر:** `return response.errors.isEmpty`

```
لو مفيش errors     → true  (تم الحفظ بنجاح)
لو في errors       → false (حصل خطأ)
```

### مثال 2: تحديث حالة الحجز (Update Mutation)

```dart
static Future<bool> updateBookingStatus(String id, String status) async {
  await requireSignedIn();
  
  // أولاً: اجيب الـ booking الحالي مع _version
  final getRequest = ModelQueries.get(BookingRequest.classType, 
    BookingRequestModelIdentifier(id: id));
  final getResponse = await Amplify.API.query(request: getRequest).response;
  
  if (getResponse.data == null) return false;
  
  final booking = getResponse.data!;
  
  // ثانياً: اعمل نسخة معدّلة
  final updatedBooking = booking.copyWith(status: status);
  
  // ثالثاً: ابعت التحديث
  final updateRequest = ModelMutations.update(updatedBooking);
  final updateResponse = await Amplify.API.mutate(request: updateRequest).response;
  
  return updateResponse.errors.isEmpty;
}
```

### مثال 3: تحديث مع `_version` يدوياً (Raw GraphQL)

هذا المثال الأهم والأصعب في المشروع:

```dart
// تحديث chatEnabled مع _version (مطلوب بسبب conflict detection)
const getDoc = 'query GetUserProfile($id: ID!) { getUserProfile(id: $id) { id _version } }';
const mutDoc = 'mutation UpdateUserProfile($input: UpdateUserProfileInput!) { updateUserProfile(input: $input) { id chatEnabled _version } }';

// الخطوة 1: اجيب الـ _version الحالي
final getResp = await Amplify.API.query(
  request: GraphQLRequest<String>(document: getDoc, variables: {'id': profile.id}),
).response;

// الخطوة 2: استخرج الـ _version من النتيجة
int version = 1;
final raw = getResp.data ?? '{}';
final idx = raw.indexOf('"_version":');
if (idx >= 0) {
  final sub = raw.substring(idx + 11);
  final end = sub.indexOf(RegExp(r'[,}]'));
  version = int.tryParse(sub.substring(0, end).trim()) ?? 1;
}

// الخطوة 3: ابعت التحديث مع الـ _version
await Amplify.API.mutate(
  request: GraphQLRequest<String>(
    document: mutDoc,
    variables: {'input': {'id': profile.id, 'chatEnabled': enable, '_version': version}},
  ),
).response;
```

**شرح الـ `_version` وليه مهم جداً:**

تخيل إنك وصديقك بتعدّلوا نفس الملف في نفس الوقت:
```
أنت:      فتحت الملف (version 1) → عدّلت → حفظت
صديقك:   فتحت الملف (version 1) → عدّلت → حفظت
```

مشكلة! إيه اللي اتحفظ؟ تعديلك أنت ولا تعديل صديقك؟

الـ **Conflict Detection** في Amplify بيحل المشكلة دي:

```
كل record في DynamoDB عنده _version رقم
لما حد يعدّل:
  - لازم يبعت الـ _version الحالي مع التعديل
  - لو الـ _version الحالي في الـ DB مختلف = conflict
  - AppSync يرفض التحديث ويرجع خطأ
```

**خطوة بخطوة:**

```
الـ _version في الـ DB = 3
        ↓
Step 1: query getUserProfile → يرجع {id: "xxx", _version: 3}
        ↓
Step 2: استخرج version = 3
        ↓
Step 3: mutation updateUserProfile(input: {id: "xxx", chatEnabled: true, _version: 3})
        ↓
AppSync يقارن: هل الـ _version المبعوت (3) = الـ _version في الـ DB (3)؟
        ↓ نعم
يحدّث الـ record ويرفع الـ _version لـ 4
        ↓ لأ
يرفض التحديث (Conflict!)
```

**لماذا نعمل Raw GraphQL هنا بدل الـ Model-based؟**

لأن الـ Model-based `ModelMutations.update()` أحياناً بيتجاهل الـ `_version` في بعض الحالات أو بيتسبب في تعارضات. الـ Raw GraphQL بيعطيك تحكم كامل.

**شرح كود استخراج الـ version:**

```dart
final raw = getResp.data ?? '{}';
// raw = '{"getUserProfile":{"id":"abc","_version":3}}'

final idx = raw.indexOf('"_version":');
// idx = موقع النص '"_version":' في الـ string

if (idx >= 0) {
  final sub = raw.substring(idx + 11);
  // idx + 11 = نقطة بعد '"_version":' مباشرة
  // sub = '3}}'

  final end = sub.indexOf(RegExp(r'[,}]'));
  // بدور على أول فاصلة أو قوس إغلاق
  // end = 1 (موقع '}')

  version = int.tryParse(sub.substring(0, end).trim()) ?? 1;
  // sub.substring(0, 1) = '3'
  // int.tryParse('3') = 3
  // version = 3
}
```

### جدول أنواع الـ Mutations في GENZ

| الـ Mutation | الوصف | متى بتستخدمها |
|-------------|-------|---------------|
| `ModelMutations.create(obj)` | إنشاء record جديد | حجز جديد، إشعار جديد، رسالة جديدة |
| `ModelMutations.update(obj)` | تعديل record موجود | تعديل حالة الحجز |
| `ModelMutations.delete(obj)` | حذف record | حذف إشعار |
| `GraphQLRequest<String>(document: mutDoc)` | Mutation يدوي | لما محتاج تحكم كامل (زي الـ _version) |

> **ملخص القسم التاسع:**
> Mutation = أي عملية بتغيّر البيانات (create/update/delete).
> `ModelMutations.create()` أسهل طريقة لإنشاء record.
> `_version` مهم جداً مع الـ conflict detection — دايماً اجلبه وابعته مع أي update.

---

---

## 10. 📖 كيف تستقبل البيانات (Queries)

### ما هي الـ Query؟

**Query** تعني "استعلام" — طلب قراءة بيانات من قاعدة البيانات بدون ما تغيّر فيها حاجة.

### مثال 1: جلب كل الاستوديوهات

```dart
static Future<List<Studio>> getStudios() async {
  await requireSignedIn();
  
  final request = ModelQueries.list(Studio.classType);
  final response = await Amplify.API.query(request: request).response;
  
  return response.data?.items.whereType<Studio>().toList() ?? [];
}
```

**شرح:**

```dart
ModelQueries.list(Studio.classType)
// بيبني هذا الـ query تلقائياً:
// query ListStudios {
//   listStudios {
//     items { id name type pricePerHour description image available }
//   }
// }

response.data?.items
// الـ items هي قايمة الاستوديوهات

.whereType<Studio>()
// فلتر — بيشيل أي null values

.toList()
// بيحوّلها لـ List<Studio>

?? []
// لو البيانات null → ارجع قايمة فاضية
```

### مثال 2: جلب إشعارات عميل معين (Raw GraphQL Query)

```dart
// جلب إشعارات العميل
const doc = '''
  query ListByEmail($email: String!) {
    appNotificationsByClientEmail(clientEmail: $email) {
      items { id clientEmail title body type time read _version }
    }
  }
''';

final resp = await Amplify.API.query(
  request: GraphQLRequest<String>(document: doc, variables: {'email': email}),
).response;
```

**لماذا Raw GraphQL هنا؟**

لأن `appNotificationsByClientEmail` هو **custom query** موجود بسبب الـ `@index` في الـ Schema. الـ `ModelQueries.list()` بيجيب **كل** الإشعارات — بس إحنا عايزين إشعارات عميل معين بس.

**شرح الـ Query:**

```graphql
query ListByEmail($email: String!) {
  # اسم الـ query المولّد من @index
  appNotificationsByClientEmail(clientEmail: $email) {
    items {
      id
      clientEmail
      title
      body
      type
      time
      read
      _version    # مهم للـ conflict detection
    }
  }
}
```

**Variables:**

```dart
variables: {'email': 'ahmed@gmail.com'}
// بيستبدل $email في الـ query
```

**معالجة الاستجابة:**

```dart
final raw = resp.data ?? '{}';
// raw = '{"appNotificationsByClientEmail":{"items":[...]}}'

// الـ JSON parsing يعطيك قايمة الإشعارات
final decoded = jsonDecode(raw);
final items = decoded['appNotificationsByClientEmail']['items'] as List;

final notifications = items.map((item) => AppNotification(
  id: item['id'],
  clientEmail: item['clientEmail'],
  title: item['title'],
  body: item['body'],
  type: item['type'],
  time: item['time'],
  read: item['read'] ?? false,
)).toList();
```

### مثال 3: جلب ملف مستخدم معين

```dart
static Future<UserProfile?> getUserProfile(String email) async {
  await requireSignedIn();
  
  const doc = '''
    query GetByEmail($email: String!) {
      userProfilesByEmail(email: $email) {
        items { id email name image type chatEnabled lastUpdated _version }
      }
    }
  ''';
  
  final resp = await Amplify.API.query(
    request: GraphQLRequest<String>(document: doc, variables: {'email': email}),
  ).response;
  
  // معالجة النتيجة
  if (resp.data == null) return null;
  
  final raw = resp.data!;
  // ... parsing كالمثال السابق
  
  return userProfile;
}
```

### الفرق بين Query Types

```
ModelQueries.list()         → كل الـ records من جدول
ModelQueries.get(id)        → record واحد بالـ id
GraphQLRequest (custom)     → query مخصص (مثل @index queries)
```

### Query مع Filter

لو عايز تفلتر النتائج بدون استخدام الـ index:

```dart
// جلب الحجوزات بحالة Pending فقط
final request = ModelQueries.list(
  BookingRequest.classType,
  where: BookingRequest.STATUS.eq('Pending'),
);
```

**ملاحظة:** ده أبطأ من الـ @index لأنه بيجيب كل البيانات ويفلترها بعدين. الـ @index أسرع بكتير.

### معالجة الأخطاء في الـ Queries

```dart
try {
  final response = await Amplify.API.query(request: request).response;
  
  if (response.errors.isNotEmpty) {
    // في errors من الـ GraphQL
    for (final error in response.errors) {
      safePrint('GraphQL Error: ${error.message}');
    }
    return [];
  }
  
  return response.data?.items.whereType<Studio>().toList() ?? [];
  
} on ApiException catch (e) {
  // خطأ في الشبكة أو الـ API
  safePrint('API Exception: ${e.message}');
  return [];
} catch (e) {
  // أي خطأ تاني
  safePrint('Unknown error: $e');
  return [];
}
```

> **ملخص القسم العاشر:**
> Query = قراءة بيانات بدون تعديل.
> `ModelQueries.list()` أسهل طريقة لجلب كل البيانات.
> الـ @index queries (زي appNotificationsByClientEmail) أسرع للبحث على حقل معين.
> دايماً اتعامل مع الـ errors.

---

---

## 11. ⚡ الـ Real-Time (Subscriptions)

### ما هو الـ Real-Time؟

تخيل إنك بتبعت رسالة لصديقك على واتساب. لازم تضغط refresh عشان تشوف رده؟ طبعاً لا! الرد بييجيلك تلقائياً. ده هو **Real-time**.

في التطبيقات العادية:
```
التطبيق بيسأل السيرفر كل 5 ثواني: "في بيانات جديدة؟"
السيرفر: لأ، لأ، لأ، آه (رسالة وصلت)
```

مع Real-time Subscriptions:
```
التطبيق فاتح "قناة اتصال" مفتوحة مع السيرفر
السيرفر: "وصلت رسالة جديدة!" → يبعت على طول
```

### كيف تعمل الـ Subscriptions في Amplify

```
WebSocket Connection
التطبيق ←──────────────→ AWS AppSync
```

الـ **WebSocket** هو نوع خاص من الاتصال — بدل الاتصال والقطع مع كل طلب، بيفتح اتصال مستمر.

### مثال: الاستماع لرسائل شات جديدة

```dart
// الاستماع لرسائل شات جديدة
static Stream<ChatMessage> subscribeToChatMessages({String? clientEmail}) {
  final controller = StreamController<ChatMessage>.broadcast();
  
  final sub = Amplify.API.subscribe(
    ModelSubscriptions.onCreate(ChatMessage.classType),
    onEstablished: () => safePrint('🔌 ChatMessages established'),
  ).listen(
    (event) {
      if (event.data == null) return;
      if (clientEmail != null &&
          event.data!.clientEmail.toLowerCase() != clientEmail.toLowerCase()) return;
      controller.add(event.data!);
    },
    onError: (e) => safePrint('ChatMessages sub error: $e'),
  );
  
  controller.onCancel = () => sub.cancel();
  return controller.stream;
}
```

**شرح كل جزء:**

---

#### `Stream<ChatMessage>`

```
Stream = تدفق بيانات مستمر (زي نهر)
       = بدل ما يرجع قيمة واحدة، بيرجع قيم متعددة على مر الوقت
ChatMessage = نوع البيانات اللي في الـ Stream
```

**الفرق:**
```
Future<ChatMessage>  = انتظر وهيجيك رسالة واحدة
Stream<ChatMessage>  = ابقى جاهز هتجيك رسائل متعددة على مر الوقت
```

---

#### `StreamController<ChatMessage>.broadcast()`

```
StreamController = "مراقب" بيتحكم في الـ Stream
.broadcast()     = يسمح لأكتر من مستمع واحد
               = بدونه: بس widget واحد يقدر يستمع
```

---

#### `Amplify.API.subscribe(ModelSubscriptions.onCreate(ChatMessage.classType))`

```
subscribe            = "اشترك" في الأحداث
ModelSubscriptions.onCreate = اسمعني لما ChatMessage جديد يتعمل
ChatMessage.classType       = نوع الـ model اللي بنستمعله
```

**الـ Subscription هيولّد هذا GraphQL تلقائياً:**
```graphql
subscription OnCreateChatMessage {
  onCreateChatMessage {
    id senderName senderEmail clientEmail text time messageType parentId
  }
}
```

---

#### `onEstablished: () => safePrint('🔌 ChatMessages established')`

```
onEstablished = callback بيتنفذ لما الاتصال يتأسس
             = بيقولك "الاشتراك شغّال دلوقتي"
```

---

#### `(event) { ... }.listen(...)`

```
listen = "ابدأ الاستماع"
event  = الحدث الجديد اللي وصل
event.data = الـ ChatMessage الجديد
```

---

#### `if (clientEmail != null && event.data!.clientEmail.toLowerCase() != clientEmail.toLowerCase()) return;`

**هذا الكود مهم جداً!**

المشكلة: الـ Subscription بيسمع **لكل** رسائل الشات في الـ DB — مش بس رسائل عميل معين.

الحل: نفلتر في الكود:
```
لو الرسالة مش بتاعة العميل ده → تجاهلها
لو الرسالة بتاعته → أضفها للـ Stream
```

`.toLowerCase()` عشان نتجنب مشاكل الحروف الكبيرة والصغيرة.

---

#### `controller.onCancel = () => sub.cancel()`

```
لما الـ widget يتحذف (مثلاً لما المستخدم يقفل الشاشة)
→ الـ Stream يتلغى
→ sub.cancel() يوقف الـ WebSocket connection
→ مش هيضيع باند ومش هيحصل memory leak
```

### أنواع الـ Subscriptions

```dart
// استمع لما record جديد يتعمل
ModelSubscriptions.onCreate(ChatMessage.classType)

// استمع لما record يتعدّل
ModelSubscriptions.onUpdate(ChatMessage.classType)

// استمع لما record يتحذف
ModelSubscriptions.onDelete(ChatMessage.classType)
```

### كيف تستخدم الـ Stream في الـ Widget

```dart
class ChatScreen extends StatefulWidget { ... }

class _ChatScreenState extends State<ChatScreen> {
  StreamSubscription<ChatMessage>? _subscription;
  List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    _subscription = AWSStorageService
        .subscribeToChatMessages(clientEmail: widget.clientEmail)
        .listen((newMessage) {
      setState(() {
        _messages.add(newMessage);
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();  // مهم: وقف الاستماع لما الشاشة تتقفل
    super.dispose();
  }
}
```

### مشاكل الـ Subscriptions وحلولها

| المشكلة | السبب | الحل |
|---------|-------|------|
| الـ Subscription مش بتشتغل | مشكلة في الـ network | استخدم Polling كـ fallback |
| بيانات تيجي للكل مش لعميل معين | الـ Subscription بيسمع للكل | فلتر في الكود |
| Memory leak | ننسى نعمل cancel | `dispose()` دايماً |
| تأخر في الاتصال | WebSocket بياخد وقت للتأسيس | `onEstablished` callback |

> **ملخص القسم الحادي عشر:**
> Subscription = استقبال بيانات حية بدون refresh.
> بيعمل WebSocket connection مفتوح مع AppSync.
> Stream في Dart = تدفق مستمر من البيانات.
> مهم جداً: عمل cancel لما الشاشة تتقفل.

---

---

## 12. 🔔 نظام الإشعارات بالتفصيل

### كيف يعمل نظام الإشعارات في GENZ

نظام الإشعارات في GENZ مش Push Notifications عادية (مش Firebase FCM). ده نظام **in-app notifications** مبني على DynamoDB + GraphQL Subscriptions.

**الفكرة:**
```
حدث ما (حجز، قبول، رفض...)
        ↓
كود بيعمل createAppNotification في DynamoDB
        ↓
Subscription على الجهاز الآخر بيسمعه
        ↓
إشعار يظهر في التطبيق
```

### الـ Sentinel Key: `'__employees__'`

هذا من أذكى أجزاء النظام!

**المشكلة:** كيف نبعت إشعار لـ "كل الموظفين"؟ مش عارفين إيميلات الموظفين دايماً.

**الحل:** اتفقنا على كلمة سرية: `'__employees__'`

```dart
// لما عميل يحجز، نبعت إشعار لـ '__employees__'
await AWSStorageService.sendNotification(
  clientEmail: '__employees__',  // sentinel key
  title: 'حجز جديد!',
  body: 'العميل $clientName طلب حجز استوديو $studioName',
  type: 'Pending',
);
```

```dart
// الموظف بيستمع للإشعارات على '__employees__'
AWSStorageService.subscribeToNotifications(
  clientEmail: '__employees__',  // نفس الـ sentinel key
);
```

**بالتالي:**
- كل الموظفين بيستمعوا على `__employees__`
- أي إشعار يتبعت على `__employees__` يوصل لكل الموظفين

### تدفق الإشعارات الكامل في GENZ

```
┌─────────────────────────────────────────────────────────────┐
│                    سيناريو: عميل يحجز                       │
└─────────────────────────────────────────────────────────────┘

1. العميل يضغط "احجز" في التطبيق
   ↓
2. بيتعمل BookingRequest في DynamoDB (status: "Pending")
   ↓
3. بيتعمل AppNotification:
   - clientEmail: "__employees__"
   - title: "حجز جديد!"
   - type: "Pending"
   ↓
4. الموظف عنده Subscription شغّال على "__employees__"
   ↓
5. الإشعار يوصله فوراً في تطبيق الموظف
   ↓
6. الموظف يضغط "قبول" أو "رفض"
   ↓
7. بيتحدّث status الـ BookingRequest
   ↓
8. بيتعمل AppNotification:
   - clientEmail: "ahmed@gmail.com"  (إيميل العميل)
   - title: "تم قبول/رفض حجزك"
   - type: "Approved" / "Rejected"
   ↓
9. العميل عنده Subscription شغّال على إيميله
   ↓
10. الإشعار يوصله فوراً
```

### سيناريو فتح الشات

```
1. الموظف يضغط "فتح الشات" للعميل
   ↓
2. بيتحدّث UserProfile.chatEnabled = true
   ↓
3. بيتعمل AppNotification:
   - clientEmail: "ahmed@gmail.com"
   - title: "تم فتح الشات!"
   - type: "chat_opened"
   ↓
4. العميل يستلم الإشعار
   ↓
5. التطبيق يعرف إن الشات مفتوح → يفتح واجهة الشات
```

### كود إرسال الإشعارات

```dart
// إرسال إشعار للموظفين (عند الحجز الجديد)
static Future<void> notifyEmployeesNewBooking({
  required String clientName,
  required String studioName,
  required String date,
}) async {
  await sendNotification(
    clientEmail: '__employees__',
    title: 'حجز جديد من $clientName',
    body: 'استوديو: $studioName\nالتاريخ: $date',
    type: 'Pending',
  );
}

// إرسال إشعار للعميل (عند القبول)
static Future<void> notifyClientApproved({
  required String clientEmail,
  required String studioName,
}) async {
  await sendNotification(
    clientEmail: clientEmail,
    title: 'تم قبول حجزك!',
    body: 'مبروك! تم قبول حجز $studioName',
    type: 'Approved',
  );
}

// إرسال إشعار للعميل (عند الرفض)
static Future<void> notifyClientRejected({
  required String clientEmail,
  required String reason,
}) async {
  await sendNotification(
    clientEmail: clientEmail,
    title: 'تم رفض حجزك',
    body: 'عذراً، تم رفض الحجز. السبب: $reason',
    type: 'Rejected',
  );
}

// إرسال إشعار للعميل (عند فتح الشات)
static Future<void> notifyClientChatOpened({
  required String clientEmail,
}) async {
  await sendNotification(
    clientEmail: clientEmail,
    title: 'تم فتح الشات!',
    body: 'يمكنك الآن التحدث مع فريقنا مباشرة',
    type: 'chat_opened',
  );
}
```

### جدول أنواع الإشعارات

| النوع (type) | من يبعته | لمن | المعنى |
|-------------|---------|-----|--------|
| `Pending` | العميل | `__employees__` | حجز جديد ينتظر المراجعة |
| `Approved` | الموظف | إيميل العميل | تم قبول الحجز |
| `Rejected` | الموظف | إيميل العميل | تم رفض الحجز |
| `chat_opened` | الموظف | إيميل العميل | تم فتح خاصية الشات |

### قراءة الإشعارات وتعليمها كـ "مقروءة"

```dart
// تعليم الإشعار كمقروء
static Future<bool> markNotificationAsRead(AppNotification notif) async {
  await requireSignedIn();
  
  // نحتاج الـ _version
  final updatedNotif = notif.copyWith(read: true);
  
  final request = ModelMutations.update(updatedNotif);
  final response = await Amplify.API.mutate(request: request).response;
  
  return response.errors.isEmpty;
}

// حذف إشعار
static Future<bool> deleteNotification(AppNotification notif) async {
  await requireSignedIn();
  
  final request = ModelMutations.delete(notif);
  final response = await Amplify.API.mutate(request: request).response;
  
  return response.errors.isEmpty;
}
```

### شاشة الإشعارات (notifications_screen.dart)

```dart
class NotificationsScreen extends StatefulWidget { ... }

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifications = [];
  StreamSubscription? _sub;
  
  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _subscribeToNewNotifications();
  }
  
  // جلب الإشعارات الموجودة
  Future<void> _loadNotifications() async {
    final notifs = await AWSStorageService.getNotifications(widget.userEmail);
    setState(() => _notifications = notifs);
  }
  
  // الاستماع للإشعارات الجديدة
  void _subscribeToNewNotifications() {
    _sub = AWSStorageService
        .subscribeToNotifications(clientEmail: widget.userEmail)
        .listen((newNotif) {
      setState(() => _notifications.insert(0, newNotif));
    });
  }
  
  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
```

> **ملخص القسم الثاني عشر:**
> نظام الإشعارات في GENZ مبني على DynamoDB + Subscriptions.
> `__employees__` هو sentinel key لإرسال إشعار لكل الموظفين.
> 4 أنواع إشعارات: Pending, Approved, Rejected, chat_opened.
> الإشعارات بتوصل real-time عن طريق GraphQL Subscriptions.

---

---

## 13. 💬 نظام الشات بالتفصيل

### كيف يعمل نظام الشات في GENZ

نظام الشات في GENZ هو محادثة **بين عميل واحد وفريق الموظفين**.

**الخصائص:**
- الشات مش متاح لكل العملاء — لازم الموظف "يفتحه" للعميل أولاً
- الموظف بيرد على العملاء من شاشة واحدة
- الرسائل بتيجي real-time

### شرط "chatEnabled"

```
chatEnabled = false   →   العميل مش يقدر يشوف أو يفتح الشات
chatEnabled = true    →   الشات متاح للعميل
```

```dart
// التحقق من حالة الشات قبل الإرسال
static Future<bool> isChatEnabled(String email) async {
  try {
    await requireSignedIn();
    
    final profile = await getUserProfile(email);
    return profile?.chatEnabled ?? false;
    
  } catch (e) {
    return false;
  }
}
```

### إرسال رسالة

```dart
static Future<bool> sendMessage({
  required String clientEmail,
  required String text,
  required String senderName,
  required String senderEmail,
  String messageType = 'text',
  String? parentId,
}) async {
  await requireSignedIn();
  
  final message = ChatMessage(
    senderName: senderName,
    senderEmail: senderEmail,
    clientEmail: clientEmail,    // إيميل العميل صاحب المحادثة
    text: text,
    time: DateTime.now().toUtc().toIso8601String(),
    messageType: messageType,
    parentId: parentId,          // لو رد على رسالة تانية
  );
  
  final response = await Amplify.API
      .mutate(request: ModelMutations.create(message))
      .response;
  
  return response.errors.isEmpty;
}
```

### الاستماع للرسائل الجديدة

```dart
// الاستماع لرسائل شات جديدة
static Stream<ChatMessage> subscribeToChatMessages({String? clientEmail}) {
  final controller = StreamController<ChatMessage>.broadcast();
  
  final sub = Amplify.API.subscribe(
    ModelSubscriptions.onCreate(ChatMessage.classType),
    onEstablished: () => safePrint('🔌 ChatMessages established'),
  ).listen(
    (event) {
      if (event.data == null) return;
      if (clientEmail != null &&
          event.data!.clientEmail.toLowerCase() != clientEmail.toLowerCase()) return;
      controller.add(event.data!);
    },
    onError: (e) => safePrint('ChatMessages sub error: $e'),
  );
  
  controller.onCancel = () => sub.cancel();
  return controller.stream;
}
```

**لماذا نفلتر على `clientEmail` بدل ما نعمل subscription مخصصة؟**

Amplify مش بيدعم subscription مع filter parameters بشكل مباشر في كل الإصدارات. الـ workaround الشائع هو:
1. اشترك في **كل** الرسائل الجديدة
2. فلتر في الكود على اللي يخصك

```dart
// فلتر الرسائل
if (clientEmail != null &&
    event.data!.clientEmail.toLowerCase() != clientEmail.toLowerCase()) {
  return;  // تجاهل هذه الرسالة
}
```

### كيف الموظف يشوف كل المحادثات

```dart
// جلب آخر رسالة لكل عميل
static Future<Map<String, ChatMessage>> getLastMessagePerClient() async {
  await requireSignedIn();
  
  const doc = '''
    query ListAllMessages {
      listChatMessages(limit: 1000) {
        items { id senderName senderEmail clientEmail text time messageType }
      }
    }
  ''';
  
  final resp = await Amplify.API.query(
    request: GraphQLRequest<String>(document: doc),
  ).response;
  
  // فرز الرسائل بالتاريخ وأخذ آخر رسالة لكل عميل
  final Map<String, ChatMessage> lastMessages = {};
  
  // ... processing code
  
  return lastMessages;
}
```

### شاشة الشات في Flutter

```dart
class ChatScreen extends StatefulWidget {
  final String clientEmail;
  final String currentUserEmail;
  final bool isEmployee;
  
  const ChatScreen({
    required this.clientEmail,
    required this.currentUserEmail,
    required this.isEmployee,
  });
}

class _ChatScreenState extends State<ChatScreen> {
  List<ChatMessage> _messages = [];
  StreamSubscription<ChatMessage>? _subscription;
  final TextEditingController _textController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadMessages();
    _startRealTimeListening();
  }
  
  // تحميل الرسائل القديمة
  Future<void> _loadMessages() async {
    const doc = '''
      query GetMessages($email: String!) {
        chatMessagesByClientEmail(clientEmail: $email) {
          items { id senderName senderEmail clientEmail text time messageType parentId }
        }
      }
    ''';
    
    final resp = await Amplify.API.query(
      request: GraphQLRequest<String>(
        document: doc,
        variables: {'email': widget.clientEmail},
      ),
    ).response;
    
    // ... parse and setState
  }
  
  // بدء الاستماع للرسائل الجديدة
  void _startRealTimeListening() {
    _subscription = AWSStorageService
        .subscribeToChatMessages(clientEmail: widget.clientEmail)
        .listen((newMessage) {
      if (mounted) {
        setState(() => _messages.add(newMessage));
        _scrollToBottom();
      }
    });
  }
  
  // إرسال رسالة
  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    
    _textController.clear();
    
    await AWSStorageService.sendMessage(
      clientEmail: widget.clientEmail,
      text: text,
      senderName: widget.isEmployee ? 'الموظف' : 'أنا',
      senderEmail: widget.currentUserEmail,
    );
  }
  
  @override
  void dispose() {
    _subscription?.cancel();
    _textController.dispose();
    super.dispose();
  }
}
```

### هيكل الرسالة في الـ UI

```
┌────────────────────────────────────────┐
│  رسالة من الموظف           10:30 AM   │
│  ┌──────────────────────────────────┐  │
│  │ أهلاً! كيف أقدر أساعدك؟        │  │
│  └──────────────────────────────────┘  │
│                                        │
│          أهلاً! عندي سؤال عن الحجز   │
│                        10:31 AM ┌────┐ │
│                                 │    │ │
│                                 └────┘ │
└────────────────────────────────────────┘
```

الرسالة من اليسار = موظف
الرسالة من اليمين = عميل (أنا)

```dart
// تحديد موقع الرسالة في الـ UI
bool isMyMessage = message.senderEmail == widget.currentUserEmail;

Align(
  alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
  child: Container(
    color: isMyMessage ? Colors.blue : Colors.grey,
    child: Text(message.text ?? ''),
  ),
)
```

### فتح وإغلاق الشات (من جهة الموظف)

```dart
// فتح الشات لعميل
static Future<bool> setChatEnabled(String email, bool enable) async {
  await requireSignedIn();
  
  // الخطوة 1: جيب الـ profile الحالي
  final profile = await getUserProfile(email);
  if (profile == null) return false;
  
  // الخطوة 2: جيب الـ _version
  const getDoc = 'query GetUserProfile($id: ID!) { getUserProfile(id: $id) { id _version } }';
  final getResp = await Amplify.API.query(
    request: GraphQLRequest<String>(
      document: getDoc,
      variables: {'id': profile.id},
    ),
  ).response;
  
  int version = 1;
  final raw = getResp.data ?? '{}';
  final idx = raw.indexOf('"_version":');
  if (idx >= 0) {
    final sub = raw.substring(idx + 11);
    final end = sub.indexOf(RegExp(r'[,}]'));
    version = int.tryParse(sub.substring(0, end).trim()) ?? 1;
  }
  
  // الخطوة 3: حدّث chatEnabled مع الـ _version
  const mutDoc = '''
    mutation UpdateUserProfile($input: UpdateUserProfileInput!) {
      updateUserProfile(input: $input) {
        id chatEnabled _version
      }
    }
  ''';
  
  final mutResp = await Amplify.API.mutate(
    request: GraphQLRequest<String>(
      document: mutDoc,
      variables: {
        'input': {
          'id': profile.id,
          'chatEnabled': enable,
          '_version': version,
        }
      },
    ),
  ).response;
  
  if (mutResp.errors.isEmpty && enable) {
    // لو فتحنا الشات، ابعت إشعار للعميل
    await sendNotification(
      clientEmail: email,
      title: 'تم فتح الشات!',
      body: 'يمكنك الآن التواصل معنا مباشرة',
      type: 'chat_opened',
    );
  }
  
  return mutResp.errors.isEmpty;
}
```

> **ملخص القسم الثالث عشر:**
> الشات في GENZ بين عميل وفريق الموظفين.
> `chatEnabled` في UserProfile بيتحكم في الوصول للشات.
> الرسائل بتوصل real-time عن طريق Subscriptions.
> الموظف بيفتح الشات → إشعار يوصل للعميل.

---

---

## 14. 🔄 الـ Polling — البديل لما الـ Subscriptions مش شغالة

### ما هو الـ Polling؟

**Polling** بالعربي تعني "الاستطلاع الدوري" — يعني بدل ما تستنى السيرفر يبعتلك (Subscriptions)، أنت بتسأله كل فترة: "في جديد؟"

```
Subscriptions:             Polling:
السيرفر → التطبيق         التطبيق → السيرفر (كل 5 ثواني)
(push)                     (pull)
```

### متى نستخدم Polling؟

```
Subscriptions مش شغالة في:
  ✗ شبكات معينة بتبلوك WebSocket
  ✗ نقطة ضعيفة في الاتصال
  ✗ بعض البيئات المقيدة

في الحالات دي → Polling كـ fallback
```

### مثال: Polling للتحقق من حالة الشات

```dart
// polling كل 5 ثواني كـ fallback
_chatPollingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
  if (!mounted) return;
  final enabled = await AWSStorageService.isChatEnabled(email);
  // process result...
});
```

**شرح كل سطر:**

---

**`_chatPollingTimer = Timer.periodic(...)`**

```
Timer.periodic = مؤقت بيتكرر كل فترة
              = بيخزّن في _chatPollingTimer عشان نوقفه لاحقاً
```

---

**`const Duration(seconds: 5)`**

```
كل كام يتكرر؟ كل 5 ثواني.
يعني في دقيقة واحدة: 12 طلب لـ AppSync.
```

**هل ده مش تقيل على السيرفر؟**

في حالتنا: عدد المستخدمين المتوقع صغير، وكل طلب بياخد بيانات صغيرة. مقبول.

لو في ملايين مستخدمين: ممكن تزود الوقت لـ 30 ثانية أو تفضّل على Subscriptions.

---

**`if (!mounted) return;`**

```
mounted = هل الـ Widget لسه موجود في الشجرة؟

لو المستخدم خرج من الشاشة:
  mounted = false
  if (!mounted) return; → وقف الـ polling
  
بدون السطر ده: هيحاول يعمل setState على widget اتحذف → خطأ!
```

---

**`final enabled = await AWSStorageService.isChatEnabled(email);`**

```
كل 5 ثواني:
  1. نسأل AppSync: هل chatEnabled = true لهذا العميل؟
  2. AppSync بيرجع true أو false
  3. نحدّث الـ UI
```

### استخدام الـ Polling في client_screen.dart

```dart
class _ClientScreenState extends State<ClientScreen> {
  Timer? _chatPollingTimer;
  bool _chatEnabled = false;
  
  @override
  void initState() {
    super.initState();
    _startPolling();
  }
  
  void _startPolling() {
    // نتحقق فوراً أول مرة
    _checkChatStatus();
    
    // ثم كل 5 ثواني
    _chatPollingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkChatStatus(),
    );
  }
  
  Future<void> _checkChatStatus() async {
    if (!mounted) return;
    
    try {
      final enabled = await AWSStorageService.isChatEnabled(widget.email);
      
      if (mounted && enabled != _chatEnabled) {
        setState(() => _chatEnabled = enabled);
        
        // لو الشات اتفتح للتو
        if (enabled && !_chatEnabled) {
          _showChatOpenedDialog();
        }
      }
    } catch (e) {
      safePrint('Polling error: $e');
    }
  }
  
  @override
  void dispose() {
    _chatPollingTimer?.cancel();  // مهم جداً!
    super.dispose();
  }
}
```

### مقارنة: Subscriptions vs Polling

| الجانب | Subscriptions | Polling |
|--------|---------------|---------|
| **السرعة** | فوري (milliseconds) | بعد ما يجي الـ interval (5 ثواني) |
| **استهلاك الباند** | أقل | أكتر |
| **استهلاك البطارية** | أقل | أكتر |
| **الموثوقية** | قد تنقطع | دايماً شغّال |
| **التعقيد** | أعلى | أبسط |
| **الاستخدام في GENZ** | Primary | Fallback |

### الاستراتيجية المثلى في GENZ

```dart
void _initializeRealtimeFeatures() async {
  // 1. جرّب الـ Subscriptions أولاً
  try {
    _subscription = AWSStorageService
        .subscribeToChatMessages(clientEmail: email)
        .listen((msg) {
      _handleNewMessage(msg);
    });
    
    safePrint('Subscriptions شغّالة ✅');
    
  } catch (e) {
    safePrint('Subscriptions فشلت ❌، بنشغّل Polling');
    
    // 2. لو فشلت، اعمل Polling كـ fallback
    _startPolling();
  }
}
```

### إيقاف الـ Polling

```dart
@override
void dispose() {
  // وقف الـ Timer
  _chatPollingTimer?.cancel();
  
  // وقف الـ Subscriptions
  _subscription?.cancel();
  
  super.dispose();
}
```

**لماذا `?.cancel()` بدل `.cancel()`؟**

```dart
_chatPollingTimer?.cancel()
// الـ ?.  تعني "لو مش null بس"
// لو _chatPollingTimer لم يُنشأ (== null) → مش هيحصل خطأ
// آمن أكتر
```

### Polling للإشعارات

```dart
// Polling للإشعارات كل 10 ثواني
Timer.periodic(const Duration(seconds: 10), (_) async {
  if (!mounted) return;
  
  final newNotifs = await AWSStorageService.getNotifications(email);
  
  if (mounted) {
    setState(() {
      // مقارنة القائمة الجديدة بالقديمة
      final oldIds = _notifications.map((n) => n.id).toSet();
      final addedNotifs = newNotifs.where((n) => !oldIds.contains(n.id)).toList();
      
      if (addedNotifs.isNotEmpty) {
        _notifications.insertAll(0, addedNotifs);
        // عرض notification badge
        _showNotificationBadge(addedNotifs.length);
      }
    });
  }
});
```

> **ملخص القسم الرابع عشر:**
> Polling = السؤال الدوري عن البيانات الجديدة.
> بنستخدمه كـ fallback لما الـ Subscriptions مش شغالة.
> مهم جداً: وقف الـ Timer في dispose() عشان تجنب memory leaks.
> الـ `if (!mounted) return` حماية ضرورية قبل أي setState في Timer.

---

---

## 📊 الملخص العام للمشروع

### خريطة كل الخدمات

```
┌─────────────────────────────────────────────────────────────┐
│                    GENZ Studios App                         │
│                                                             │
│  Flutter Widgets                                            │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐  │
│  │  Client  │ │ Employee │ │  Booking │ │ Notifications│  │
│  │  Screen  │ │  Screen  │ │  Screen  │ │    Screen    │  │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └──────┬───────┘  │
│       │            │            │               │           │
│  ─────┼────────────┼────────────┼───────────────┼───────    │
│       │       AWSStorageService (aws_storage.dart)          │
│  ─────┼────────────┼────────────┼───────────────┼───────    │
│       │            │            │               │           │
│  ┌────▼────────────▼────────────▼───────────────▼───────┐  │
│  │                 AWS Amplify Library                   │  │
│  └────┬──────────────┬──────────────┬────────────────────┘  │
│       │              │              │                        │
│  ┌────▼─────┐ ┌──────▼────┐ ┌──────▼────┐                  │
│  │ Cognito  │ │ AppSync   │ │    S3     │                  │
│  │ (Auth)   │ │  (API)    │ │ (Storage) │                  │
│  └──────────┘ └──────┬────┘ └───────────┘                  │
│                       │                                     │
│                 ┌─────▼─────┐                               │
│                 │ DynamoDB  │                               │
│                 │(Database) │                               │
│                 └───────────┘                               │
└─────────────────────────────────────────────────────────────┘
```

### جدول كل الجداول في DynamoDB

| الجدول | الهدف | الحقول الأساسية |
|--------|-------|-----------------|
| Studio | بيانات الاستوديوهات | id, name, type, pricePerHour |
| BookingRequest | طلبات الحجز | id, clientEmail, studio, status |
| ChatMessage | رسائل الشات | id, clientEmail, senderEmail, text |
| AppNotification | الإشعارات | id, clientEmail, title, type, read |
| UserProfile | ملفات المستخدمين | id, email, chatEnabled |

### جدول تدفق البيانات

| الحدث | من | لمن | نوع العملية |
|-------|-----|-----|-------------|
| حجز جديد | العميل | DynamoDB | Mutation (create BookingRequest) |
| إشعار للموظفين | العميل | `__employees__` | Mutation (create AppNotification) |
| قبول/رفض الحجز | الموظف | DynamoDB | Mutation (update BookingRequest) |
| إشعار للعميل | الموظف | إيميل العميل | Mutation (create AppNotification) |
| فتح الشات | الموظف | UserProfile | Mutation (update chatEnabled) |
| رسالة شات | أي طرف | DynamoDB | Mutation (create ChatMessage) |
| جلب الاستوديوهات | التطبيق | DynamoDB | Query |
| جلب الإشعارات | التطبيق | DynamoDB | Query (byClientEmail) |

---

## 🎓 نصائح للمبتدئين

### الأخطاء الشائعة وكيفية تجنبها

```
1. نسيت amplify push بعد تعديل الـ Schema
   → التغييرات موجودة في الكود بس مش في السحابة
   → الحل: amplify push دايماً بعد أي تعديل

2. نسيت amplify codegen models بعد الـ push
   → الـ Dart models مش متحدثة
   → الحل: amplify codegen models بعد كل push

3. استخدمت update بدون _version
   → AppSync بيرفض التحديث (Conflict error)
   → الحل: دايماً اجلب الـ _version الحالي قبل الـ update

4. نسيت dispose للـ Subscriptions والـ Timers
   → Memory leak وأخطاء setState على widget محذوف
   → الحل: دايماً cancel في dispose()

5. تشغيل runApp قبل configureAmplify
   → خطأ في بدء التطبيق
   → الحل: configureAmplify أول ثم runApp
```

### أوامر مفيدة للـ Debug

```bash
# مشاهدة logs التطبيق
flutter run --verbose

# تحديث الـ Dart models
amplify codegen models

# مشاهدة حالة الـ Backend
amplify status

# تحديث Amplify CLI
npm install -g @aws-amplify/cli

# فتح AppSync Console
amplify console api

# فتح Cognito Console
amplify console auth
```

---

> **الكلمة الأخيرة:**
> GENZ Studios هو تطبيق Flutter متكامل مبني على AWS Amplify.
> الـ Backend كله في السحابة: Cognito للمصادقة، AppSync للـ API، DynamoDB لقاعدة البيانات، S3 للصور.
> الـ real-time مبني على GraphQL Subscriptions مع Polling كـ fallback.
> نظام الإشعارات والشات مبني بالكامل داخل التطبيق بدون Push Notifications خارجية.
> كل العمليات مركزية في ملف `aws_storage.dart`.

---

*تم إعداد هذا التوثيق لمشروع GENZ Studios — جميع الحقوق محفوظة.*
