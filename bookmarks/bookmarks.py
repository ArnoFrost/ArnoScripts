from bs4 import BeautifulSoup
import pandas as pd

def extract_bookmarks_iterative(soup):
    bookmarks = []
    stack = [(soup.find('dl'), "")]  # 初始化栈，包含根元素和当前路径

    while stack:
        current_dl, parent_path = stack.pop()  # 从栈中取出当前元素和路径
        for dt in current_dl.find_all('dt', recursive=False):  # 只处理当前层的dt
            h3 = dt.find('h3')
            if h3:
                title = h3.text.strip()  # 获取文件夹或书签的标题
                current_path = f"{parent_path}/{title}" if parent_path else title  # 更新当前路径

                # 处理文件夹
                sub_dl = dt.find('dl')
                if sub_dl:
                    stack.append((sub_dl, current_path))  # 如果是文件夹，推入栈中以便后续处理
                    print(f"Found folder: {current_path}")  # 打印找到的文件夹
            else:
                # 处理书签
                a = dt.find('a')
                if a:
                    title = a.text.strip()
                    url = a['href']
                    bookmarks.append({'title': title, 'url': url, 'path': parent_path})  # 保存路径信息
                    print(f"Added bookmark: {title} - {url} (Path: {parent_path})")  # 打印已添加的书签

    return bookmarks

def save_to_excel(bookmarks, excel_file):
    df = pd.DataFrame(bookmarks)
    df.to_excel(excel_file, index=False)

def read_bookmarks(html_file):
    with open(html_file, 'r', encoding='utf-8') as file:
        content = file.read()
        print("HTML Content Loaded:")  # 打印加载的内容
        print(content[:1000])  # 打印文件内容的前1000个字符，避免输出过多
        soup = BeautifulSoup(content, 'html.parser')
        return extract_bookmarks_iterative(soup)

# 示例使用
if __name__ == "__main__":
    html_file = '/Users/xuxin/Desktop/bookmarks_2024_9_20.html'  # 替换为你的书签HTML文件路径
    excel_file = '/Users/xuxin/Desktop/test.xlsx'  # 输出的Excel文件名
    bookmarks = read_bookmarks(html_file)
    if bookmarks:
        save_to_excel(bookmarks, excel_file)
        print(f"书签信息已保存到 {excel_file}")
    else:
        print("没有找到任何书签信息。")