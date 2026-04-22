-- ========================================
-- 文件管理系統 完整資料庫建置腳本（整合版）
-- 版本：v4.0
-- 日期：2026-04-22
-- 說明：整合所有資料庫建置、升級、異動腳本
--       包含：基礎建置、帳號系統、樹狀資料夾、課別管理、
--            分享連結、時效區清理、備份設定、安全強化
-- 執行前：請先備份現有資料庫！
-- ========================================

USE master;
GO

-- ========================================
-- 第 1 階段：建立資料庫
-- ========================================
PRINT N'========== 第 1 階段：建立資料庫 ==========';
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'文件管理系統DB')
BEGIN
    CREATE DATABASE [文件管理系統DB]
    COLLATE Chinese_Taiwan_Stroke_CI_AS;
    PRINT N'✓ 資料庫建立完成';
END
ELSE
BEGIN
    PRINT N'✓ 資料庫已存在，跳過建立';
END
GO

USE [文件管理系統DB];
GO

-- ========================================
-- 第 2 階段：建立基礎資料表
-- ========================================
PRINT N'========== 第 2 階段：建立基礎資料表 ==========';
GO

-- 組別設定表
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='組別設定' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[組別設定] (
        [組別編號]              INT IDENTITY(1,1) PRIMARY KEY,
        [組別名稱]              NVARCHAR(50) NOT NULL,
        [組別代碼]              NVARCHAR(20) NOT NULL UNIQUE,
        [負責人姓名]            NVARCHAR(50),
        [負責人帳號編號]        INT NULL,
        [備用負責人帳號編號]    INT NULL,
        [負責人IP]              NVARCHAR(50),
        [備用負責人IP]          NVARCHAR(50),
        [建立時間]              DATETIME DEFAULT GETDATE(),
        [是否啟用]              BIT DEFAULT 1
    );
    PRINT N'✓ 組別設定表建立完成';
END
GO

-- 執行檔IP白名單表
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='執行檔IP白名單' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[執行檔IP白名單] (
        [白名單編號]    INT IDENTITY(1,1) PRIMARY KEY,
        [IP位址]        NVARCHAR(50) NOT NULL,
        [說明]          NVARCHAR(200),
        [建立者]        NVARCHAR(100),
        [建立時間]      DATETIME DEFAULT GETDATE(),
        [是否啟用]      BIT DEFAULT 1
    );
    PRINT N'✓ 執行檔IP白名單表建立完成';
END
GO

-- 系統設定表
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='系統設定' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[系統設定] (
        [設定編號]      INT IDENTITY(1,1) PRIMARY KEY,
        [設定名稱]      NVARCHAR(100) NOT NULL UNIQUE,
        [設定值]        NVARCHAR(MAX),
        [說明]          NVARCHAR(500),
        [修改時間]      DATETIME DEFAULT GETDATE()
    );
    PRINT N'✓ 系統設定表建立完成';
END
GO

-- ========================================
-- 第 3 階段：建立帳號系統
-- ========================================
PRINT N'========== 第 3 階段：建立帳號系統 ==========';
GO

-- 使用者帳號表
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='使用者帳號' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[使用者帳號] (
        [帳號編號]              INT IDENTITY(1,1) PRIMARY KEY,
        [登入帳號]              NVARCHAR(20) NOT NULL UNIQUE,
        [姓名]                  NVARCHAR(50) NOT NULL,
        [姓名代號]              NVARCHAR(10) NOT NULL UNIQUE,
        [組別編號]              INT NULL,
        [主要課別編號]          INT NULL,
        [課別]                  NVARCHAR(50) NULL,
        [分機]                  NVARCHAR(20) NULL,
        [密碼雜湊]              NVARCHAR(256) NOT NULL,
        [密碼鹽值]              NVARCHAR(128) NOT NULL,
        [角色]                  NVARCHAR(20) NOT NULL DEFAULT N'員工'
                                CHECK ([角色] IN (N'超管',N'資訊人員',N'負責人',N'員工',N'外包')),
        [員工類型]              NVARCHAR(10) NOT NULL DEFAULT N'員工'
                                CHECK ([員工類型] IN (N'員工',N'外包')),
        [帳號狀態]              NVARCHAR(10) NOT NULL DEFAULT N'待審核'
                                CHECK ([帳號狀態] IN (N'待審核',N'啟用',N'停用')),
        [申請時間]              DATETIME DEFAULT GETDATE(),
        [核准時間]              DATETIME NULL,
        [核准者帳號]            NVARCHAR(20) NULL,
        [最後登入]              DATETIME NULL,
        [最後登入IP]            NVARCHAR(50) NULL,
        [登入失敗次數]          INT DEFAULT 0,
        [登入失敗時間]          DATETIME NULL,
        [帳號鎖定時間]          DATETIME NULL,
        [建立者]                NVARCHAR(20) NULL,
        [備註]                  NVARCHAR(200) NULL,
        FOREIGN KEY ([組別編號]) REFERENCES [組別設定]([組別編號])
    );
    CREATE INDEX IX_帳號_登入帳號  ON [使用者帳號]([登入帳號]);
    CREATE INDEX IX_帳號_組別      ON [使用者帳號]([組別編號]);
    CREATE INDEX IX_帳號_角色      ON [使用者帳號]([角色]);
    CREATE INDEX IX_帳號_狀態      ON [使用者帳號]([帳號狀態]);
    PRINT N'✓ 使用者帳號表建立完成';
END
GO

-- 資訊人員IP表
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='資訊人員IP' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[資訊人員IP] (
        [編號]          INT IDENTITY(1,1) PRIMARY KEY,
        [帳號編號]      INT NOT NULL,
        [IP位址]        NVARCHAR(50) NOT NULL,
        [說明]          NVARCHAR(100) NULL,
        [建立時間]      DATETIME DEFAULT GETDATE(),
        [是否啟用]      BIT DEFAULT 1,
        FOREIGN KEY ([帳號編號]) REFERENCES [使用者帳號]([帳號編號])
    );
    PRINT N'✓ 資訊人員IP表建立完成';
END
GO

-- ========================================
-- 第 4 階段：建立樹狀資料夾結構
-- ========================================
PRINT N'========== 第 4 階段：建立樹狀資料夾結構 ==========';
GO

-- 資料夾表
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='資料夾' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[資料夾] (
        [資料夾編號]    INT IDENTITY(1,1) PRIMARY KEY,
        [父資料夾編號]  INT NULL,
        [組別編號]      INT NOT NULL,
        [課別編號]      INT NULL,
        [儲存區類型]    NVARCHAR(10) NOT NULL CHECK ([儲存區類型] IN (N'永久區', N'時效區')),
        [資料夾名稱]    NVARCHAR(200) NOT NULL,
        [實體路徑]      NVARCHAR(1000) NOT NULL,
        [建立者IP]      NVARCHAR(50),
        [建立時間]      DATETIME DEFAULT GETDATE(),
        [是否刪除]      BIT DEFAULT 0,
        [刪除時間]      DATETIME,
        [刪除者IP]      NVARCHAR(50),
        FOREIGN KEY ([父資料夾編號]) REFERENCES [資料夾]([資料夾編號]),
        FOREIGN KEY ([組別編號]) REFERENCES [組別設定]([組別編號])
    );
    CREATE INDEX IX_資料夾_父編號 ON [資料夾]([父資料夾編號]);
    CREATE INDEX IX_資料夾_組別  ON [資料夾]([組別編號]);
    PRINT N'✓ 資料夾表建立完成';
END
GO

-- ========================================
-- 第 5 階段：建立課別管理
-- ========================================
PRINT N'========== 第 5 階段：建立課別管理 ==========';
GO

-- 課別設定表
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='課別設定' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[課別設定] (
        [課別編號]      INT IDENTITY(1,1) PRIMARY KEY,
        [組別編號]      INT NOT NULL,
        [課別名稱]      NVARCHAR(50) NOT NULL,
        [課別代碼]      NVARCHAR(20) NOT NULL,
        [負責人帳號]    NVARCHAR(50),
        [建立時間]      DATETIME DEFAULT GETDATE(),
        [是否啟用]      BIT DEFAULT 1,
        FOREIGN KEY ([組別編號]) REFERENCES [組別設定]([組別編號]),
        UNIQUE ([組別編號], [課別代碼])
    );
    CREATE INDEX IX_課別設定_組別 ON [課別設定]([組別編號]);
    PRINT N'✓ 課別設定表建立完成';
END
GO

-- 更新資料夾表的課別 FK
IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys 
    WHERE name = 'FK_資料夾_課別' AND parent_object_id = OBJECT_ID('資料夾')
)
BEGIN
    IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='資料夾' AND COLUMN_NAME='課別編號')
    BEGIN
        ALTER TABLE [dbo].[資料夾] ADD CONSTRAINT FK_資料夾_課別
            FOREIGN KEY ([課別編號]) REFERENCES [課別設定]([課別編號]);
        PRINT N'✓ 資料夾課別外鍵建立完成';
    END
END
GO

-- 更新使用者帳號表的課別 FK
IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys 
    WHERE name = 'FK_帳號_課別' AND parent_object_id = OBJECT_ID('使用者帳號')
)
BEGIN
    IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='使用者帳號' AND COLUMN_NAME='主要課別編號')
    BEGIN
        ALTER TABLE [dbo].[使用者帳號] ADD CONSTRAINT FK_帳號_課別
            FOREIGN KEY ([主要課別編號]) REFERENCES [課別設定]([課別編號]);
        PRINT N'✓ 使用者帳號課別外鍵建立完成';
    END
END
GO

-- ========================================
-- 第 6 階段：建立檔案管理
-- ========================================
PRINT N'========== 第 6 階段：建立檔案管理 ==========';
GO

-- 檔案主檔表
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='檔案主檔' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[檔案主檔] (
        [檔案編號]          INT IDENTITY(1,1) PRIMARY KEY,
        [組別編號]          INT NOT NULL,
        [課別編號]          INT NULL,
        [資料夾編號]        INT NULL,
        [儲存區類型]        NVARCHAR(10) NOT NULL CHECK ([儲存區類型] IN (N'永久區', N'時效區', N'資源回收桶')),
        [原始檔名]          NVARCHAR(500) NOT NULL,
        [儲存檔名]          NVARCHAR(500) NOT NULL,
        [檔案路徑]          NVARCHAR(1000) NOT NULL,
        [檔案大小]          BIGINT,
        [檔案類型]          NVARCHAR(50),
        [副檔名]            NVARCHAR(20),
        [上傳者帳號]        NVARCHAR(50),
        [上傳者IP]          NVARCHAR(50),
        [上傳時間]          DATETIME DEFAULT GETDATE(),
        [到期時間]          DATETIME,
        [審核狀態]          NVARCHAR(20) DEFAULT N'待審核' CHECK ([審核狀態] IN (N'待審核', N'已通過', N'未通過', N'不需審核')),
        [審核者帳號]        NVARCHAR(50),
        [審核者IP]          NVARCHAR(50),
        [審核時間]          DATETIME,
        [審核備註]          NVARCHAR(500),
        [是否刪除]          BIT DEFAULT 0,
        [刪除時間]          DATETIME,
        [刪除者帳號]        NVARCHAR(50),
        [刪除者IP]          NVARCHAR(50),
        [描述]              NVARCHAR(1000),
        [版本號]            INT DEFAULT 1,
        [父檔案編號]        INT,
        FOREIGN KEY ([組別編號]) REFERENCES [組別設定]([組別編號]),
        FOREIGN KEY ([課別編號]) REFERENCES [課別設定]([課別編號]),
        FOREIGN KEY ([資料夾編號]) REFERENCES [資料夾]([資料夾編號])
    );
    CREATE INDEX IX_檔案主檔_組別 ON [檔案主檔]([組別編號]);
    CREATE INDEX IX_檔案主檔_儲存區 ON [檔案主檔]([儲存區類型]);
    CREATE INDEX IX_檔案主檔_資料夾編號 ON [檔案主檔]([資料夾編號]);
    PRINT N'✓ 檔案主檔表建立完成';
END
GO

-- ========================================
-- 第 7 階段：建立操作紀錄與稽核
-- ========================================
PRINT N'========== 第 7 階段：建立操作紀錄與稽核 ==========';
GO

-- 操作紀錄表
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='操作紀錄' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[操作紀錄] (
        [紀錄編號]          BIGINT IDENTITY(1,1) PRIMARY KEY,
        [檔案編號]          INT,
        [帳號編號]          INT NULL,
        [登入帳號]          NVARCHAR(50) NULL,
        [操作類型]          NVARCHAR(20) NOT NULL CHECK ([操作類型] IN (N'上傳', N'下載', N'預覽', N'編輯', N'刪除', N'審核', N'移動', N'登入', N'登出', N'新增資料夾', N'刪除資料夾', N'改名資料夾')),
        [操作者IP]          NVARCHAR(50) NOT NULL,
        [操作者主機名]      NVARCHAR(200),
        [操作時間]          DATETIME DEFAULT GETDATE(),
        [操作結果]          NVARCHAR(20) DEFAULT N'成功' CHECK ([操作結果] IN (N'成功', N'失敗', N'拒絕')),
        [失敗原因]          NVARCHAR(500),
        [操作前內容]        NVARCHAR(MAX),
        [操作後內容]        NVARCHAR(MAX),
        [檔案名稱]          NVARCHAR(500),
        [備註]              NVARCHAR(1000),
        FOREIGN KEY ([檔案編號]) REFERENCES [檔案主檔]([檔案編號]),
        FOREIGN KEY ([帳號編號]) REFERENCES [使用者帳號]([帳號編號])
    );
    CREATE INDEX IX_操作紀錄_操作時間 ON [操作紀錄]([操作時間] DESC);
    CREATE INDEX IX_操作紀錄_IP ON [操作紀錄]([操作者IP]);
    CREATE INDEX IX_操作紀錄_帳號編號 ON [操作紀錄]([帳號編號]);
    PRINT N'✓ 操作紀錄表建立完成';
END
GO

-- 資安稽核紀錄表
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='資安稽核紀錄' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[資安稽核紀錄] (
        [稽核編號]      BIGINT IDENTITY(1,1) PRIMARY KEY,
        [稽核類型]      NVARCHAR(50) NOT NULL,
        [風險等級]      NVARCHAR(10) NOT NULL CHECK ([風險等級] IN (N'低', N'中', N'高', N'嚴重')),
        [來源IP]        NVARCHAR(50),
        [目標資源]      NVARCHAR(500),
        [事件描述]      NVARCHAR(1000),
        [發生時間]      DATETIME DEFAULT GETDATE(),
        [處理狀態]      NVARCHAR(20) DEFAULT N'未處理',
        [處理備註]      NVARCHAR(500),
        [處理時間]      DATETIME
    );
    CREATE INDEX IX_資安稽核_時間 ON [資安稽核紀錄]([發生時間] DESC);
    PRINT N'✓ 資安稽核紀錄表建立完成';
END
GO

-- 個資稽核紀錄表
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='個資稽核紀錄' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[個資稽核紀錄] (
        [稽核編號]      BIGINT IDENTITY(1,1) PRIMARY KEY,
        [檔案編號]      INT,
        [偵測類型]      NVARCHAR(50),
        [偵測內容]      NVARCHAR(MAX),
        [操作者IP]      NVARCHAR(50),
        [操作類型]      NVARCHAR(20),
        [偵測時間]      DATETIME DEFAULT GETDATE(),
        [風險等級]      NVARCHAR(10),
        [處理狀態]      NVARCHAR(20) DEFAULT N'未處理',
        FOREIGN KEY ([檔案編號]) REFERENCES [檔案主檔]([檔案編號])
    );
    PRINT N'✓ 個資稽核紀錄表建立完成';
END
GO

-- ========================================
-- 第 8 階段：建立檔案分享連結
-- ========================================
PRINT N'========== 第 8 階段：建立檔案分享連結 ==========';
GO

-- 檔案分享連結表
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='檔案分享連結' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[檔案分享連結] (
        [分享編號]          INT IDENTITY(1,1) PRIMARY KEY,
        [檔案編號]          INT NOT NULL,
        [分享連結]          NVARCHAR(100) NOT NULL UNIQUE,
        [分享者帳號]        NVARCHAR(50) NOT NULL,
        [分享時間]          DATETIME DEFAULT GETDATE(),
        [到期時間]          DATETIME,
        [下載次數]          INT DEFAULT 0,
        [最大下載次數]      INT,
        [密碼]              NVARCHAR(100),
        [是否啟用]          BIT DEFAULT 1,
        FOREIGN KEY ([檔案編號]) REFERENCES [檔案主檔]([檔案編號]),
        INDEX IX_分享連結 ([分享連結])
    );
    CREATE INDEX IX_分享連結_檔案 ON [檔案分享連結]([檔案編號]);
    CREATE INDEX IX_分享連結_分享者 ON [檔案分享連結]([分享者帳號]);
    PRINT N'✓ 檔案分享連結表建立完成';
END
GO

-- ========================================
-- 第 9 階段：建立跨組操作權限
-- ========================================
PRINT N'========== 第 9 階段：建立跨組操作權限 ==========';
GO

-- 跨組操作權限表
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='跨組操作權限' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[跨組操作權限] (
        [權限編號]          INT IDENTITY(1,1) PRIMARY KEY,
        [帳號編號]          INT NOT NULL,
        [允許組別編號]      INT NOT NULL,
        [操作類型]          NVARCHAR(20) NOT NULL CHECK ([操作類型] IN (N'永久區', N'時效區', N'全部')),
        [設定者]            NVARCHAR(50),
        [設定時間]          DATETIME DEFAULT GETDATE(),
        [是否啟用]          BIT DEFAULT 1,
        FOREIGN KEY ([帳號編號]) REFERENCES [使用者帳號]([帳號編號]),
        FOREIGN KEY ([允許組別編號]) REFERENCES [組別設定]([組別編號]),
        UNIQUE ([帳號編號], [允許組別編號])
    );
    CREATE INDEX IX_跨組操作_帳號 ON [跨組操作權限]([帳號編號]);
    CREATE INDEX IX_跨組操作_組別 ON [跨組操作權限]([允許組別編號]);
    PRINT N'✓ 跨組操作權限表建立完成';
END
GO

-- ========================================
-- 第 10 階段：建立排程清理紀錄
-- ========================================
PRINT N'========== 第 10 階段：建立排程清理紀錄 ==========';
GO

-- 排程清理紀錄表
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='排程清理紀錄' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[排程清理紀錄] (
        [清理編號]          BIGINT IDENTITY(1,1) PRIMARY KEY,
        [檔案編號]          INT NULL,
        [清理類型]          NVARCHAR(50) NOT NULL,
        [清理狀態]          NVARCHAR(20) DEFAULT N'成功',
        [清理時間]          DATETIME DEFAULT GETDATE(),
        [備註]              NVARCHAR(500),
        INDEX IX_清理時間 ([清理時間] DESC)
    );
    PRINT N'✓ 排程清理紀錄表建立完成';
END
GO

-- ========================================
-- 第 11 階段：建立備份管理
-- ========================================
PRINT N'========== 第 11 階段：建立備份管理 ==========';
GO

-- 備份設定表
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='備份設定' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[備份設定] (
        [備份編號]          INT IDENTITY(1,1) PRIMARY KEY,
        [備份名稱]          NVARCHAR(100) NOT NULL,
        [來源路徑]          NVARCHAR(500) NOT NULL,
        [目標路徑]          NVARCHAR(500) NOT NULL,
        [備份類型]          NVARCHAR(20) NOT NULL DEFAULT N'完整'
                            CHECK ([備份類型] IN (N'完整',N'增量')),
        [備份排程]          NVARCHAR(20) NOT NULL DEFAULT N'手動'
                            CHECK ([備份排程] IN (N'手動',N'每日',N'每週',N'每月')),
        [排程時間]          NVARCHAR(10) NULL,
        [保留份數]          INT DEFAULT 7,
        [是否啟用]          BIT DEFAULT 1,
        [最後備份時間]      DATETIME NULL,
        [最後備份結果]      NVARCHAR(20) NULL,
        [最後備份訊息]      NVARCHAR(500) NULL,
        [建立時間]          DATETIME DEFAULT GETDATE(),
        [建立者]            NVARCHAR(50) NULL
    );
    PRINT N'✓ 備份設定表建立完成';
END
GO

-- 備份紀錄表
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='備份紀錄' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[備份紀錄] (
        [紀錄編號]          BIGINT IDENTITY(1,1) PRIMARY KEY,
        [備份編號]          INT NOT NULL,
        [開始時間]          DATETIME DEFAULT GETDATE(),
        [結束時間]          DATETIME NULL,
        [結果]              NVARCHAR(20) NOT NULL DEFAULT N'執行中'
                            CHECK ([結果] IN (N'執行中',N'成功',N'失敗',N'部分成功')),
        [複製檔案數]        INT DEFAULT 0,
        [複製大小MB]        DECIMAL(10,2) DEFAULT 0,
        [錯誤訊息]          NVARCHAR(MAX) NULL,
        [執行者IP]          NVARCHAR(50) NULL,
        FOREIGN KEY ([備份編號]) REFERENCES [備份設定]([備份編號])
    );
    PRINT N'✓ 備份紀錄表建立完成';
END
GO

-- ========================================
-- 第 12 階段：初始化系統設定
-- ========================================
PRINT N'========== 第 12 階段：初始化系統設定 ==========';
GO

IF NOT EXISTS (SELECT * FROM [系統設定])
BEGIN
    INSERT INTO [系統設定] ([設定名稱], [設定值], [說明]) VALUES
    (N'儲存根路徑', N'D:\儲存區', N'檔案儲存根目錄'),
    (N'永久區路徑', N'D:\儲存區\永久區', N'永久保存區路徑'),
    (N'時效區路徑', N'D:\儲存區\時效區', N'時效保存區路徑'),
    (N'資源回收桶路徑', N'D:\儲存區\資源回收桶', N'資源回收桶路徑'),
    (N'時效區保存天數', N'30', N'時效區檔案保存天數'),
    (N'回收桶清除天數', N'60', N'回收桶超過此天數自動永久刪除'),
    (N'最大上傳檔案大小MB', N'500', N'單一檔案最大上傳大小(MB)'),
    (N'系統名稱', N'文件管理系統', N'系統顯示名稱'),
    (N'AD網域', N'', N'Active Directory 網域名稱(移機後設定)'),
    (N'AD啟用', N'false', N'是否啟用AD驗證'),
    (N'檔案分享連結有效期天數', N'7', N'分享連結預設有效期（天）'),
    (N'時效區自動清理啟用', N'true', N'是否啟用時效區自動清理'),
    (N'時效區清理時間', N'02:00', N'每日清理時間（HH:MM）'),
    (N'永久區需要審核', N'true', N'永久區檔案是否需要審核'),
    (N'登入失敗鎖定次數', N'5', N'單一帳號或IP連續登入失敗達此值時暫時鎖定'),
    (N'登入鎖定分鐘數', N'15', N'登入失敗過多後的暫時鎖定分鐘數'),
    (N'登入失敗計算分鐘數', N'15', N'計算登入失敗次數的時間視窗');
    PRINT N'✓ 系統設定初始化完成';
END
GO

-- ========================================
-- 第 13 階段：初始化組別與課別
-- ========================================
PRINT N'========== 第 13 階段：初始化組別與課別 ==========';
GO

IF NOT EXISTS (SELECT * FROM [組別設定])
BEGIN
    INSERT INTO [組別設定] ([組別名稱], [組別代碼]) VALUES
    (N'第一組', N'G01'),
    (N'第二組', N'G02'),
    (N'第三組', N'G03'),
    (N'第四組', N'G04'),
    (N'第五組', N'G05'),
    (N'第六組', N'G06'),
    (N'第七組', N'G07'),
    (N'第八組', N'G08'),
    (N'第九組', N'G09'),
    (N'第十組', N'G10'),
    (N'第十一組', N'G11'),
    (N'第十二組', N'G12'),
    (N'第十三組', N'G13'),
    (N'第十四組', N'G14'),
    (N'第十五組', N'G15');
    PRINT N'✓ 預設組別初始化完成';
END
GO

IF NOT EXISTS (SELECT * FROM [課別設定])
BEGIN
    INSERT INTO [課別設定] ([組別編號], [課別名稱], [課別代碼], [是否啟用]) VALUES
    (1, N'課別 1-1', N'D01', 1),
    (1, N'課別 1-2', N'D02', 1),
    (1, N'課別 1-3', N'D03', 1),
    (2, N'課別 2-1', N'D04', 1),
    (2, N'課別 2-2', N'D05', 1),
    (3, N'課別 3-1', N'D06', 1);
    PRINT N'✓ 預設課別初始化完成';
END
GO

-- ========================================
-- 第 14 階段：初始化根資料夾
-- ========================================
PRINT N'========== 第 14 階段：初始化根資料夾 ==========';
GO

-- 為每個組別建立根資料夾（永久區）
INSERT INTO [資料夾] ([父資料夾編號],[組別編號],[儲存區類型],[資料夾名稱],[實體路徑],[建立者IP])
SELECT NULL, g.組別編號, N'永久區',
       g.組別名稱,
       N'D:\儲存區\永久區\' + g.組別代碼,
       N'SYSTEM'
FROM 組別設定 g
WHERE g.是否啟用=1
  AND NOT EXISTS (
    SELECT 1 FROM 資料夾 f
    WHERE f.組別編號=g.組別編號 AND f.儲存區類型=N'永久區' AND f.父資料夾編號 IS NULL
  );

-- 為每個組別建立根資料夾（時效區）
INSERT INTO [資料夾] ([父資料夾編號],[組別編號],[儲存區類型],[資料夾名稱],[實體路徑],[建立者IP])
SELECT NULL, g.組別編號, N'時效區',
       g.組別名稱,
       N'D:\儲存區\時效區\' + g.組別代碼,
       N'SYSTEM'
FROM 組別設定 g
WHERE g.是否啟用=1
  AND NOT EXISTS (
    SELECT 1 FROM 資料夾 f
    WHERE f.組別編號=g.組別編號 AND f.儲存區類型=N'時效區' AND f.父資料夾編號 IS NULL
  );

PRINT N'✓ 根資料夾初始化完成';
GO

-- ========================================
-- 第 15 階段：建立預存程序
-- ========================================
PRINT N'========== 第 15 階段：建立預存程序 ==========';
GO

-- 檢查永久區權限預存程序
IF EXISTS (SELECT * FROM sys.objects WHERE name='sp檢查永久區權限' AND type='P')
BEGIN
    DROP PROCEDURE [sp檢查永久區權限];
END
GO

CREATE PROCEDURE [sp檢查永久區權限]
    @帳號編號 INT,
    @組別編號 INT,
    @課別編號 INT
AS
BEGIN
    DECLARE @角色 NVARCHAR(20);
    DECLARE @使用者組別 INT;
    
    SELECT @角色 = [角色], @使用者組別 = [組別編號]
    FROM [使用者帳號]
    WHERE [帳號編號] = @帳號編號;
    
    IF @角色 = N'超管'
        RETURN 1;
    
    IF @角色 = N'負責人' AND @使用者組別 = @組別編號
        RETURN 1;
    
    IF @角色 = N'員工' AND @使用者組別 = @組別編號
        RETURN 1;
    
    IF EXISTS (
        SELECT 1 FROM [跨組操作權限]
        WHERE [帳號編號] = @帳號編號
        AND [允許組別編號] = @組別編號
        AND [操作類型] IN (N'永久區', N'全部')
        AND [是否啟用] = 1
    )
        RETURN 1;
    
    RETURN 0;
END
GO

PRINT N'✓ 永久區權限檢查預存程序建立完成';

-- 時效區自動清理預存程序
IF EXISTS (SELECT * FROM sys.objects WHERE name='sp時效區自動清理' AND type='P')
BEGIN
    DROP PROCEDURE [sp時效區自動清理];
END
GO

CREATE PROCEDURE [sp時效區自動清理]
AS
BEGIN
    DECLARE @清理檔案數 INT = 0;
    DECLARE @清理大小 DECIMAL(10,2) = 0;
    
    BEGIN TRY
        SELECT @清理檔案數 = COUNT(*), @清理大小 = SUM([檔案大小]) / 1024 / 1024
        FROM [檔案主檔]
        WHERE [儲存區類型] = N'時效區'
        AND [到期時間] < GETDATE()
        AND [是否刪除] = 0;
        
        UPDATE [檔案主檔]
        SET [儲存區類型] = N'資源回收桶',
            [是否刪除] = 1,
            [刪除時間] = GETDATE()
        WHERE [儲存區類型] = N'時效區'
        AND [到期時間] < GETDATE()
        AND [是否刪除] = 0;
        
        INSERT INTO [排程清理紀錄] ([清理類型], [清理狀態], [備註])
        VALUES (N'時效區自動清理', N'成功', N'已清理 ' + CAST(@清理檔案數 AS NVARCHAR(10)) + N' 個檔案');
        
        PRINT N'✓ 時效區清理完成：' + CAST(@清理檔案數 AS NVARCHAR(10)) + N' 個檔案';
    END TRY
    BEGIN CATCH
        INSERT INTO [排程清理紀錄] ([清理類型], [清理狀態], [備註])
        VALUES (N'時效區自動清理', N'失敗', ERROR_MESSAGE());
        
        PRINT N'✗ 時效區清理失敗：' + ERROR_MESSAGE();
    END CATCH
END
GO

PRINT N'✓ 時效區自動清理預存程序建立完成';

-- ========================================
-- 第 16 階段：建立檢視
-- ========================================
PRINT N'========== 第 16 階段：建立檢視 ==========';
GO

-- 課別樹狀結構檢視
IF EXISTS (SELECT * FROM sys.views WHERE name='v課別樹狀')
BEGIN
    DROP VIEW [v課別樹狀];
END
GO

CREATE VIEW [v課別樹狀] AS
SELECT 
    g.[組別編號],
    g.[組別名稱],
    d.[課別編號],
    d.[課別名稱],
    d.[課別代碼],
    d.[負責人帳號],
    d.[是否啟用],
    COUNT(DISTINCT f.[資料夾編號]) AS [資料夾數],
    COUNT(DISTINCT fm.[檔案編號]) AS [檔案數]
FROM [組別設定] g
LEFT JOIN [課別設定] d ON g.[組別編號] = d.[組別編號]
LEFT JOIN [資料夾] f ON d.[課別編號] = f.[課別編號]
LEFT JOIN [檔案主檔] fm ON f.[資料夾編號] = fm.[資料夾編號]
WHERE g.[是否啟用] = 1
GROUP BY g.[組別編號], g.[組別名稱], d.[課別編號], d.[課別名稱], d.[課別代碼], d.[負責人帳號], d.[是否啟用];
GO

PRINT N'✓ 課別樹狀結構檢視建立完成';

-- ========================================
-- 完成
-- ========================================
PRINT N'';
PRINT N'╔════════════════════════════════════════════════════════╗';
PRINT N'║  文件管理系統 資料庫建置完成！                          ║';
PRINT N'║  版本：v4.0 整合版                                      ║';
PRINT N'║  包含：基礎建置、帳號系統、樹狀資料夾、課別管理、      ║';
PRINT N'║       分享連結、時效區清理、備份設定、安全強化         ║';
PRINT N'╚════════════════════════════════════════════════════════╝';
PRINT N'';
PRINT N'✓ 所有資料表建立完成';
PRINT N'✓ 所有索引建立完成';
PRINT N'✓ 所有預存程序建立完成';
PRINT N'✓ 所有檢視建立完成';
PRINT N'✓ 系統設定初始化完成';
PRINT N'✓ 組別與課別初始化完成';
PRINT N'✓ 根資料夾初始化完成';
PRINT N'';
PRINT N'下一步：';
PRINT N'1. 在 IIS 中部署應用程式';
PRINT N'2. 在 Global.asax 中初始化排程清理任務';
PRINT N'3. 建立儲存區目錄結構（D:\儲存區）';
PRINT N'4. 設定應用程式池權限';
PRINT N'5. 使用預設超管帳號登入（帳號：000000，密碼：Admin@123456）';
PRINT N'6. 修改超管密碼';
PRINT N'7. 建立其他帳號與課別';
GO
