using System;
using System.Configuration;

/// <summary>
/// 系統設定讀取輔助：優先讀資料庫，其次讀 Web.config
/// </summary>
public static class 設定輔助
{
    public static string 取得字串(string 名稱, string 預設值 = "", params string[] 別名)
    {
        string 值 = 從資料庫取值(名稱);
        if (!string.IsNullOrEmpty(值)) return 值;

        foreach (string key in 組合名稱(名稱, 別名))
        {
            string appValue = ConfigurationManager.AppSettings[key];
            if (!string.IsNullOrEmpty(appValue)) return appValue;
        }

        return 預設值 ?? "";
    }

    public static int 取得整數(string 名稱, int 預設值, params string[] 別名)
    {
        int value;
        return int.TryParse(取得字串(名稱, "", 別名), out value) ? value : 預設值;
    }

    public static bool 取得布林(string 名稱, bool 預設值, params string[] 別名)
    {
        bool value;
        return bool.TryParse(取得字串(名稱, "", 別名), out value) ? value : 預設值;
    }

    private static string 從資料庫取值(string 名稱)
    {
        try
        {
            object result = 資料庫輔助.查詢單值(
                "SELECT TOP 1 設定值 FROM 系統設定 WHERE 設定名稱=@名稱",
                資料庫輔助.P("@名稱", 名稱));
            return result == null ? "" : result.ToString();
        }
        catch
        {
            return "";
        }
    }

    private static System.Collections.Generic.IEnumerable<string> 組合名稱(string 名稱, string[] 別名)
    {
        yield return 名稱;
        if (別名 == null) yield break;
        foreach (string item in 別名)
        {
            if (!string.IsNullOrWhiteSpace(item))
                yield return item;
        }
    }
}
