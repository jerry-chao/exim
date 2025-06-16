## 业务层&IM层的分层

业务通过IM层完成数据变更的在线同步。

- 重关联数据

  - 个人属性（昵称、头像、签名）
  - 好友列表
  - 加入的群组列表
  - 我发送的消息状态（已读、未读）

- 中关联数据

  - 群组属性（群名称、群头像、群公告，人数）
  - 群组人员列表

- 轻关联数据

  - 群人员的属性（昵称、头像、签名）
  - 其他人发送的消息状态

## 业务状态数据同步

### 重关联数据

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

#### 混合场景

- 用户的昵称修改
- 被加入群组
- 我发送的投票消息，被其他人投票了

```mermaid
sequenceDiagram
    participant SDK
    participant ConnectionService
    participant UserService
    participant UserA

    Note over SDK,UserService: 离线期间
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

### 群组场景

群组相关的操作，某个人操作群组，需要通知到群组内的其他在线用户。
离线用户在登录或者合适的时机同步响应的变更数据。

#### 在线场景

```mermaid
sequenceDiagram
    participant SDK
    participant ConnectionService
    participant GroupService
    participant MessageService

    SDK->>+ConnectionService: 申请加入群组
    ConnectionService->>+GroupService: 执行申请加入群组的逻辑
    GroupService->>-ConnectionService: 返回执行结果
    ConnectionService->>-SDK: 返回执行结果
    GroupService->>+MessageService: 执行消息的推送，通知到在线的用户，通知到申请加入群组的审批用户
```

#### 离线场景

```mermaid
sequenceDiagram
    participant SDK
    participant ConnectionService
    participant GroupService
    participant UserA

    Note over SDK,GroupService: 离线期间
    UserA->>GroupService: 申请加入群组

    Note over SDK,GroupService: 上线后
    SDK->>+ConnectionService: 同步离线期间的申请加入群组申请的列表数据
    ConnectionService->>+GroupService: 获取离线存储的申请加入群组数据
    GroupService-->>-ConnectionService: 获取离线存储的申请加入群组数据
    ConnectionService-->>-SDK: 返回离线申请加入群组申请的列表数据
```

