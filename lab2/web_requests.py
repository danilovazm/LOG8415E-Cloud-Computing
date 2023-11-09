import requests
import threading, time

def post_requsts(url):
    headers={
        'Content-type':'application/json', 
        'Accept':'application/json'
    }

    print("Thread: began")

    for i in range(3):
        myobj = {'key': 'value'}
        response = requests.post(url, json=myobj, headers=headers)
        print(f"Response from {url}: {response.status_code}, {response.text}")
    return

# Create and start threads for each URL
def requests_main(DNS):
    threads = []
    url = [f'http://{DNS}:5000/new_request']
    thread1 = threading.Thread(target=post_requsts, args=(url))
    thread1.start()
    threads.append(thread1)

    thread2 = threading.Thread(target=post_requsts, args=(url))
    thread2.start()
    threads.append(thread2)

    thread3 = threading.Thread(target=post_requsts, args=(url))
    thread3.start()
    threads.append(thread3)

    thread4 = threading.Thread(target=post_requsts, args=(url))
    thread4.start()
    threads.append(thread4)

    thread5 = threading.Thread(target=post_requsts, args=(url))
    thread5.start()
    threads.append(thread5)
    # Wait for all threads to finish
    for thread in threads:
        thread.join()
    
    return