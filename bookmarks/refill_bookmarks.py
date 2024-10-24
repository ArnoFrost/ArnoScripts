def save_to_html(bookmarks, html_file):
    html_content = '''<!DOCTYPE NETSCAPE-Bookmark-file-1>
    <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
    <TITLE>Bookmarks</TITLE>
    <H1>Bookmarks</H1>
    <DL><p>'''

    for bookmark in bookmarks:
        if bookmark['url']:
            html_content += f'<DT><A HREF="{bookmark["url"]}" ADD_DATE="0">{bookmark["new_title"]}</A>\n'
        else:
            html_content += f'<DT><H3>{bookmark["new_title"]}</H3>\n<DL><p>\n'

    html_content += '</DL><p></DL><p>'

    with open(html_file, 'w', encoding='utf-8') as file:
        file.write(html_content)

# 示例使用
if __name__ == "__main__":
    excel_file = 'bookmarks.xlsx'  # 输入的Excel文件名
    html_file = 'new_bookmarks.html'  # 输出的HTML文件名
    df = pd.read_excel(excel_file)

    # 将新名称和路径组合成书签列表
    bookmarks = [{'title': row['new_title'], 'url': row['url'], 'path': row['path']} for index, row in df.iterrows()]
    save_to_html(bookmarks, html_file)
    print(f"新的书签已保存到 {html_file}")