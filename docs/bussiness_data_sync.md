# 业务层

## 业务数据的分类

业务通过IM层完成数据变更的在线同步。

业务层的数据分类，主要根据数据的重要程度进行分类。

### 强关联数据

    账号级别的重要数据，一般需要完整的进行同步，需要保证强一致性。

  - 个人属性（昵称、头像、签名）
  - 好友列表
  - 加入的群组列表以及群组属性（群名称、群头像、群公告，人数）
  - 我发送的消息状态（已读、未读）

### 弱关联数据

    弱关联数据，一般需要进行部分同步，保证数据最终一致性。比如漫游消息在下拉的时候拉取更多，群组成员列表在拉取更多的时候拉取更多。
  
  - 群组人员列表
  - 消息列表


  - 群人员的属性（昵称、头像、签名）
  - 其他人发送的消息状态

## 业务状态数据同步

### 强关联数据

  - 个人属性（昵称、头像、签名）
  - 好友列表
  - 加入的群组列表
  - 我发送的消息状态（已读、未读）

下面个人的属性为例子，业务侧理解为 ```昵称```

个人昵称的变更其他的设备，其他设备能够及时更新昵称。

1. 在线场景下，其他的设备能够实时收到变更的通知。
2. 离线场景下，其他的设备能够通过拉取最新的个人属性数据，更新昵称。（此处可以通过版本号来判断是否需要更新）

#### 在线场景

```mermaid
sequenceDiagram
    participant SDK
    participant ConnectionService
    participant UserService
    participant MessageService

    SDK->>+ConnectionService: 修改个人属性(昵称)
    ConnectionService->>+UserService: 执行修改个人属性的逻辑
    UserService->>-ConnectionService: 返回执行结果
    ConnectionService->>-SDK: 返回执行结果
    UserService->>+MessageService: 执行消息的推送，通知到在线的其他设备
```

#### 离线场景

```mermaid
sequenceDiagram
    participant SDK
    participant ConnectionService
    participant UserService
    participant UserA

    Note over SDK,UserService: 离线期间
    UserA->>UserService: 修改个人属性（昵称），version=1

    Note over SDK,UserService: 上线后
    SDK->>+ConnectionService: 同步个人属性的数据，本地version=0
    ConnectionService->>+UserService: 获取个人属性的数据，本地version=0
    UserService-->>-ConnectionService: 获取个人属性的数据，服务端version=1
    ConnectionService-->>-SDK: 返回个人属性的数据，服务端version=1
```

### 群组消息已读

#### 在线场景

```mermaid
sequenceDiagram
    participant SDK
    participant ConnectionService
    participant GroupACKService
    participant MessageService

    SDK->>+ConnectionService: 修改某条消息的ACK状态
    ConnectionService->>+GroupACKService: 执行GroupACK的逻辑
    GroupACKService->>-ConnectionService: 返回执行结果
    ConnectionService->>-SDK: 返回执行结果
    GroupACKService->>+MessageService: 执行消息的推送，通知到在线的用户
```

#### 离线场景

```mermaid
sequenceDiagram
    participant SDK
    participant ConnectionService
    participant GroupACKService
    participant UserA

    Note over SDK,GroupACKService: 离线期间
    UserA->>GroupACKService: 修改某条消息的ACK状态

    Note over SDK,GroupACKService: 上线后
    SDK->>+ConnectionService: 同步离线期间的ACK状态
    ConnectionService->>+GroupACKService: 获取离线存储的ACK数据
    GroupACKService-->>-ConnectionService: 获取离线存储的ACK数据
    ConnectionService-->>-SDK: 返回离线ACK数据
```

### 好友场景

好友相关的操作，某个人操作好友，需要通知到好友的在线用户。
离线用户在登录同步相应的变更数据。

#### 在线场景

```mermaid
sequenceDiagram
    participant SDK
    participant ConnectionService
    participant FriendService
    participant MessageService

    SDK->>+ConnectionService: 申请添加好友
    ConnectionService->>+FriendService: 执行添加好友的逻辑
    FriendService->>-ConnectionService: 返回执行结果
    ConnectionService->>-SDK: 返回执行结果
    FriendService->>+MessageService: 执行消息的推送，通知到在线的用户，通知到申请添加好友的用户
```

#### 离线场景

```mermaid
sequenceDiagram
    participant SDK
    participant ConnectionService
    participant FriendService
    participant UserA

    Note over SDK,FriendService: 离线期间
    UserA->>FriendService: 申请添加好友

    Note over SDK,FriendService: 上线后
    SDK->>+ConnectionService: 同步离线期间的好友申请
    ConnectionService->>+FriendService: 获取离线存储的好友申请数据
    FriendService-->>-ConnectionService: 获取离线存储的好友申请数据
    ConnectionService-->>-SDK: 返回离线好友申请数据
```

### 混合场景

- 用户的昵称修改
- 被加入群组
- 我发送的投票消息，被其他人投票了

```mermaid
sequenceDiagram
    participant UserA
    participant ConnectionService
    participant UserService
    participant GroupService
    participant ReactionService

    Note over UserA,UserService: 离线期间
    UserA->>UserService: 修改个人属性（昵称），version=1
    UserA->>GroupService: 被加入群组，version=1
    UserA->>ReactionService: 我发送的投票消息，被其他人投票了，version=1
    
    Note over UserA,UserService: 上线后
    UserA->>+ConnectionService: 同步个人属性的数据，version=0，群组数据version=0，投票数据version=0
    ConnectionService-->>-UserA: 同步请求已经受理完成

    Note over UserA,UserService: 异步发送个人属性相关的数据
    ConnectionService->>+UserService: 获取个人属性的数据，version=0
    UserService-->>-ConnectionService: 发送个人属性的数据，version=1到客户端
    ConnectionService-->>UserA: 发送个人属性的数据，version=1到客户端

    Note over UserA,GroupService: 异步发送群组相关的数据
    ConnectionService->>+GroupService: 获取加入的群组的数据，version=0
    GroupService-->>-ConnectionService: 发送加入的群组的数据，version=1到客户端
    ConnectionService-->>UserA: 发送加入的群组的数据，version=1到客户端

    Note over UserA,ReactionService: 异步发送投票相关的数据
    ConnectionService->>+ReactionService: 获取投票的数据，version=0
    ReactionService-->>-ConnectionService: 发送投票的数据，version=1到客户端
    ConnectionService-->>UserA: 发送投票的数据，version=1到客户端
```

## 弱关联数据

### 群组加人场景

群组加人场景，群主加人，需要通知到被加人的在线用户。

#### 在线场景

```mermaid
sequenceDiagram
    participant Owner
    participant UserA
    participant ConnectionService
    participant GroupService

    Owner->>GroupService: 添加人员到群组
    GroupService->>ConnectionService: 通知群组内的人员增加
    GroupService->>UserA: 通知群组的成员，有新的成员加入群组
```

#### 离线场景

```mermaid
sequenceDiagram
    participant Owner
    participant UserA
    participant ConnectionService
    participant GroupService

    Note over Owner,GroupService: 离线期间
    Owner->>GroupService: 添加人员到群组

    Note over UserA,GroupService: 上线后
    UserA->>+GroupService: 用户打开群组成员列表的时候，拉取群组成员列表
    GroupService-->>-UserA: 获取群组成员列表
```

### 群组消息列表

群组消息列表，用户打开群组消息列表，需要拉取群组消息列表。

#### 在线场景

```mermaid
sequenceDiagram
    participant UserA
    participant UserB
    participant ConnectionService
    participant MessageService

    UserA->>+ConnectionService: 发送消息到群组
    ConnectionService->>+MessageService: 发送消息到群组
    MessageService->>ConnectionService: 通知群组中所有在线的用户
    ConnectionService->>UserB: 通知群组消息列表
```

#### 离线场景

```mermaid
sequenceDiagram
    participant UserA
    participant UserB
    participant ConnectionService
    participant MessageService

    Note over UserA,MessageService: 离线期间
    UserA->>+ConnectionService: 发送消息到群组
    ConnectionService->>+MessageService: 发送消息到群组

    Note over UserB,MessageService: 上线后
    UserB->>+ConnectionService: 进入到会话，<br/>拉取群组漫游消息<br/>指定时间之前的消息
    ConnectionService->>+MessageService: 拉取群组漫游消息
    MessageService-->>-ConnectionService: 返回群组漫游消息
    ConnectionService-->>-UserB: 返回群组漫游消息
```

### 群组成员头像属性

群组成员头像属性，用户打开群组成员列表，需要拉取群组成员头像属性。
该场景不区分在线和离线，因为该场景是弱关联数据，不需要保证强一致性。

```mermaid
sequenceDiagram
    participant UserA
    participant GroupService

    UserA->>+GroupService: 如果本地没有群组成员头像属性，则拉取群组成员头像属性
    GroupService-->>-UserA: 返回群组成员头像属性
    UserA->>UserA: 缓存群组成员头像属性到本地

    Note over UserA,GroupService: 用户查看具体某个群组成员的头像属性
    UserA->>+GroupService: 拉取群组成员头像属性，比对是否有变更
    GroupService-->>-UserA: 返回群组成员头像属性
    UserA->>UserA: 缓存群组成员头像属性到本地
```

基于场景的数据对比，可能通过SDK的很难确定，基于业务侧的场景，可以确定。就上面这个群组成员属性，
可以通过下面的结构存储相关数据，

| 群组ID | 群组成员ID | 群组成员头像属性 |
| ------- | ---------- | ---------------- |
| 1       | 1          | xxxxx                |
| 1       | 2          | yyyyy                |

数据量本身不大的话，就没有version对比的必要性，直接返回相应的数据即可。
