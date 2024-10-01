import requests
import time
import concurrent.futures
from collections import Counter

INGRESS_HOST = "localhost"
INGRESS_PORT = "5000"

def send_request(endpoint):
    url = f"http://{INGRESS_HOST}:{INGRESS_PORT}{endpoint}"
    try:
        response = requests.get(url, timeout=2)
        return f"{endpoint}: {response.status_code}"
    except requests.exceptions.RequestException as e:
        return f"{endpoint}: Error - {str(e)}"

def run_test(duration=30):
    end_time = time.time() + duration
    results = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=50) as executor:
        while time.time() < end_time:
            futures = [executor.submit(send_request, '/error') for _ in range(15)] + \
                      [executor.submit(send_request, '/api/hello') for _ in range(5)]
            for future in concurrent.futures.as_completed(futures):
                results.append(future.result())
    return results

def analyze_results(results):
    counter = Counter(results)
    total = len(results)
    print(f"\nTotal requests: {total}")
    for result, count in counter.items():
        print(f"{result}: {count} ({count/total*100:.2f}%)")

if __name__ == "__main__":
    print("Test 1: Initial behavior (30 seconds)")
    results1 = run_test()
    analyze_results(results1)
    
    print("\nWaiting for circuit breaker to potentially open...")
    time.sleep(5)
    
    print("\nTest 2: Behavior after potential circuit breaking (30 seconds)")
    results2 = run_test()
    analyze_results(results2)

    print("\nComparison:")
    print("Before:")
    analyze_results(results1)
    print("After:")
    analyze_results(results2)
