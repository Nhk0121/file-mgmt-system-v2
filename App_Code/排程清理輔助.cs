using System;
using System.Data;
using System.IO;

/// <summary>
/// 時效區自動清理機制
/// 功能：
/// 1. 定期檢查時效區過期檔案
/// 2. 將過期檔案移到回收桶
/// 3. 記錄清理操作
/// 4. 支援手動觸發清理
/// </summary>
public static class 排程清理輔助
{
    /// <summary>
    /// 執行時效區清理（定期排程或手動觸發）
    /// </summary>
    public static void 執行時效區清理()
    {
        try
        {
            DateTime 現在時間 = DateTime.Now;

            // 查詢所有過期的時效區檔案
            DataTable dt = 資料庫輔助.查詢(
                @"SELECT 檔案編號, 檔案路徑, 原始檔名, 儲存區類型, 組別編號, 課別編號, 資料夾編號
                  FROM 檔案主檔
                  WHERE 儲存區類型=N'時效區' 
                  AND 是否刪除=0
                  AND 到期時間 < @現在
                  ORDER BY 到期時間 ASC",
                資料庫輔助.P("@現在", 現在時間)
            );

            int 清理數量 = 0;
            int 失敗數量 = 0;

            foreach (DataRow 檔案 in dt.Rows)
            {
                try
                {
                    int 檔案編號 = Convert.ToInt32(檔案["檔案編號"]);
                    string 檔案路徑 = 檔案["檔案路徑"].ToString();

                    // 移除實體檔案
                    if (File.Exists(檔案路徑))
                    {
                        try
                        {
                            File.Delete(檔案路徑);
                        }
                        catch (Exception ex)
                        {
                            // 記錄警告但繼續清理
                            記錄清理(檔案編號, "警告", string.Format("刪除實體檔案失敗: {0}", ex.Message));
                        }
                    }

                    // 更新資料庫
                    資料庫輔助.執行(
                        @"UPDATE 檔案主檔 
                          SET 儲存區類型=N'資源回收桶', 是否刪除=1, 刪除時間=GETDATE()
                          WHERE 檔案編號=@編號",
                        資料庫輔助.P("@編號", 檔案編號)
                    );

                    // 記錄操作
                    操作紀錄輔助.記錄(檔案編號, "自動清理", "系統", "成功", null, null,
                        string.Format("時效區檔案已過期，自動移到回收桶"));

                    記錄清理(檔案編號, "成功", "檔案已移到回收桶");

                    清理數量++;
                }
                catch (Exception ex)
                {
                    失敗數量++;
                    記錄清理(Convert.ToInt32(檔案["檔案編號"]), "失敗", ex.Message);
                }
            }

            // 記錄清理統計
            記錄清理統計(清理數量, 失敗數量);
        }
        catch (Exception ex)
        {
            記錄清理(0, "錯誤", string.Format("時效區清理失敗: {0}", ex.Message));
        }
    }

    /// <summary>
    /// 執行回收桶清理（刪除超過指定天數的檔案）
    /// </summary>
    public static void 執行回收桶清理(int 保留天數 = 30)
    {
        try
        {
            DateTime 清理時間 = DateTime.Now.AddDays(-保留天數);

            // 查詢所有應該永久刪除的回收桶檔案
            DataTable dt = 資料庫輔助.查詢(
                @"SELECT 檔案編號, 檔案路徑, 原始檔名
                  FROM 檔案主檔
                  WHERE 儲存區類型=N'資源回收桶' 
                  AND 是否刪除=1
                  AND 刪除時間 < @清理時間
                  ORDER BY 刪除時間 ASC",
                資料庫輔助.P("@清理時間", 清理時間)
            );

            int 清理數量 = 0;
            int 失敗數量 = 0;

            foreach (DataRow 檔案 in dt.Rows)
            {
                try
                {
                    int 檔案編號 = Convert.ToInt32(檔案["檔案編號"]);
                    string 檔案路徑 = 檔案["檔案路徑"].ToString();

                    // 移除實體檔案
                    if (File.Exists(檔案路徑))
                    {
                        try
                        {
                            File.Delete(檔案路徑);
                        }
                        catch (Exception ex)
                        {
                            記錄清理(檔案編號, "警告", string.Format("刪除實體檔案失敗: {0}", ex.Message));
                        }
                    }

                    // 從資料庫刪除記錄
                    資料庫輔助.執行(
                        @"DELETE FROM 檔案主檔 WHERE 檔案編號=@編號",
                        資料庫輔助.P("@編號", 檔案編號)
                    );

                    // 刪除相關的分享連結
                    資料庫輔助.執行(
                        @"DELETE FROM 檔案分享連結 WHERE 檔案編號=@編號",
                        資料庫輔助.P("@編號", 檔案編號)
                    );

                    記錄清理(檔案編號, "成功", "檔案已永久刪除");

                    清理數量++;
                }
                catch (Exception ex)
                {
                    失敗數量++;
                    記錄清理(Convert.ToInt32(檔案["檔案編號"]), "失敗", ex.Message);
                }
            }

            記錄清理統計(清理數量, 失敗數量);
        }
        catch (Exception ex)
        {
            記錄清理(0, "錯誤", string.Format("回收桶清理失敗: {0}", ex.Message));
        }
    }

    /// <summary>
    /// 清理過期的分享連結
    /// </summary>
    public static void 清理過期分享連結()
    {
        try
        {
            // 停用所有過期的分享連結
            資料庫輔助.執行(
                @"UPDATE 檔案分享連結 
                  SET 是否啟用=0 
                  WHERE 到期時間 < GETDATE() AND 是否啟用=1"
            );

            // 刪除 30 天前停用的分享連結
            資料庫輔助.執行(
                @"DELETE FROM 檔案分享連結 
                  WHERE 是否啟用=0 AND 分享時間 < DATEADD(DAY, -30, GETDATE())"
            );

            記錄清理(0, "成功", "過期分享連結已清理");
        }
        catch (Exception ex)
        {
            記錄清理(0, "錯誤", string.Format("分享連結清理失敗: {0}", ex.Message));
        }
    }

    /// <summary>
    /// 記錄清理操作
    /// </summary>
    private static void 記錄清理(int 檔案編號, string 狀態, string 備註)
    {
        try
        {
            資料庫輔助.執行(
                @"INSERT INTO 排程清理紀錄 (檔案編號, 清理類型, 清理狀態, 清理時間, 備註)
                  VALUES (@檔案, @類型, @狀態, GETDATE(), @備註)",
                資料庫輔助.P("@檔案", 檔案編號 > 0 ? (object)檔案編號 : DBNull.Value),
                資料庫輔助.P("@類型", "自動清理"),
                資料庫輔助.P("@狀態", 狀態),
                資料庫輔助.P("@備註", 備註)
            );
        }
        catch (Exception ex)
        {
            // 記錄失敗，但不中斷清理流程
        }
    }

    /// <summary>
    /// 記錄清理統計
    /// </summary>
    private static void 記錄清理統計(int 成功數, int 失敗數)
    {
        try
        {
            資料庫輔助.執行(
                @"INSERT INTO 排程清理紀錄 (清理類型, 清理狀態, 清理時間, 備註)
                  VALUES (@類型, @狀態, GETDATE(), @備註)",
                資料庫輔助.P("@類型", "清理統計"),
                資料庫輔助.P("@狀態", "完成"),
                資料庫輔助.P("@備註", string.Format("成功: {0}, 失敗: {1}", 成功數, 失敗數))
            );
        }
        catch (Exception ex)
        {
            // 記錄失敗，但不中斷清理流程
        }
    }

    /// <summary>
    /// 取得清理紀錄
    /// </summary>
    public static DataTable 取得清理紀錄(int 天數 = 30)
    {
        try
        {
            return 資料庫輔助.查詢(
                @"SELECT 清理編號, 檔案編號, 清理類型, 清理狀態, 清理時間, 備註
                  FROM 排程清理紀錄
                  WHERE 清理時間 > DATEADD(DAY, -@天數, GETDATE())
                  ORDER BY 清理時間 DESC",
                資料庫輔助.P("@天數", 天數)
            );
        }
        catch (Exception ex)
        {
            throw new Exception("取得清理紀錄失敗：" + ex.Message);
        }
    }

    /// <summary>
    /// 取得清理統計
    /// </summary>
    public static DataTable 取得清理統計()
    {
        try
        {
            return 資料庫輔助.查詢(
                @"SELECT 清理狀態, COUNT(*) AS 數量, MAX(清理時間) AS 最後清理時間
                  FROM 排程清理紀錄
                  WHERE 清理時間 > DATEADD(DAY, -30, GETDATE())
                  GROUP BY 清理狀態"
            );
        }
        catch (Exception ex)
        {
            throw new Exception("取得清理統計失敗：" + ex.Message);
        }
    }
}

/// <summary>
/// 排程清理 Global.asax 整合
/// 在 Application_Start 中新增排程任務
/// </summary>
public static class 排程清理配置
{
    /// <summary>
    /// 初始化排程清理任務
    /// 建議在 Global.asax 的 Application_Start 中呼叫
    /// </summary>
    public static void 初始化排程()
    {
        // 使用 System.Timers.Timer 實現定期清理
        System.Timers.Timer timer = new System.Timers.Timer();
        timer.Interval = 24 * 60 * 60 * 1000; // 每 24 小時執行一次
        timer.Elapsed += (sender, e) =>
        {
            try
            {
                排程清理輔助.執行時效區清理();
                排程清理輔助.執行回收桶清理(30); // 保留 30 天
                排程清理輔助.清理過期分享連結();
            }
            catch (Exception ex)
            {
                // 記錄錯誤
                System.Diagnostics.EventLog.WriteEntry("文件管理系統", 
                    string.Format("排程清理失敗: {0}", ex.Message), 
                    System.Diagnostics.EventLogEntryType.Error);
            }
        };
        timer.AutoReset = true;
        timer.Enabled = true;
    }
}
