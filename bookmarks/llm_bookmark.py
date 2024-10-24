import openai

def rename_bookmarks_with_llm(excel_file):
    df = pd.read_excel(excel_file)

    # 假设你已经设置了 OpenAI API 密钥
    openai.api_key = '你的API密钥'

    new_titles = []
    for index, row in df.iterrows():
        title = row['title']
        # 调用 LLM 进行重命名
        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "user", "content": f"请为以下书签提供一个更好的名称: {title}"}
            ]
        )
        new_title = response['choices'][0]['message']['content']
        new_titles.append(new_title)

    df['new_title'] = new_titles
    df.to_excel(excel_file, index=False)
    print(f"新名称已保存到 {excel_file}")

# 示例使用
if __name__ == "__main__":
    excel_file = 'bookmarks.xlsx'  # 输入的Excel文件名
    rename_bookmarks_with_llm(excel_file)