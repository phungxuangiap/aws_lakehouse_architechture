import json
import random
from faker import Faker
from datetime import datetime, timedelta

fake = Faker()

def generate_mock_data(num_records=1000):
    game_list = []
    player_activity_list = []
    
    # --- 1. Generate Game_Info ---
    genres = ['MMO', 'FPS', 'RPG', 'Adventure', 'Strategy', 'Simulation', 'Sports']
    ratings = ['E', 'T', 'M', 'E10+']
    
    for _ in range(num_records//3): # Tạo 100 game mẫu để gán cho các hoạt động của player
        game_id = f"GAME-{fake.unique.random_number(digits=5)}"
        game_info = {
            "GameID": game_id,
            "Genre": random.choice(genres),
            "Publisher": fake.company(),
            "Rating": random.choice(ratings),
            "Game_Length": random.randint(5, 200),
            "ReleaseDate": fake.date_between(start_date='-5y', end_date='today').isoformat()
        }
        game_list.append(game_info)

    # --- 2. Generate Player_Activity ---
    activity_types = ['Playing', 'AFK', 'In-Queue']
    play_modes = ['Solo', 'Co-op', 'PvP']

    for _ in range(num_records):
        start_time = fake.date_time_between(start_date='-30d', end_date='now')
        # EndTime có thể null hoặc sau StartTime khoảng vài giờ
        end_time = start_time + timedelta(minutes=random.randint(10, 300)) if random.random() > 0.1 else None
        
        activity = {
            "PlayerID": f"USER-{fake.random_number(digits=6)}",
            "GameID": random.choice(game_list)["GameID"],
            "SessionID": fake.uuid4(),
            "StartTime": start_time.isoformat(),
            "EndTime": end_time.isoformat() if end_time else None,
            "ActivityType": random.choice(activity_types),
            "Level": random.randint(1, 100),
            "ExperiencePoints": round(random.uniform(100.0, 50000.0), 2),
            "AchievementsUnlocked": random.randint(0, 5),
            "CurrencyEarned": round(random.uniform(0.0, 1000.0), 2),
            "CurrencySpent": round(random.uniform(0.0, 800.0), 2),
            "QuestsCompleted": random.randint(0, 10),
            "EnemiesDefeated": random.randint(0, 150),
            "ItemsCollected": random.randint(0, 50),
            "Deaths": random.randint(0, 20),
            "DistanceTraveled": round(random.uniform(0.1, 50.0), 2),
            "ChatMessagesSent": random.randint(0, 100),
            "TeamEventsParticipated": random.randint(0, 3),
            "SkillLevelUp": random.randint(0, 2),
            "PlayMode": random.choice(play_modes)
        }
        player_activity_list.append(activity)
    return game_list, player_activity_list


import boto3
import os


def upload_to_s3(game_list, player_activity_list):
    """
    Upload dữ liệu lên S3 (Bronze layer)
    
    Environment variables:
    - S3_BUCKET: Tên S3 bucket (được set từ lambda.tf)
    """
    s3 = boto3.client('s3')
    bucket_name = os.environ.get('S3_BUCKET')
    
    if not bucket_name:
        raise ValueError("S3_BUCKET environment variable not set")
    
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    
    # Upload Game Info
    print(f"Uploading game_info to s3://{bucket_name}/bronze/")
    s3.put_object(
        Bucket=bucket_name,
        Key=f"bronze/game_info_{timestamp}.json",
        Body=json.dumps(game_list, indent=2)
    )
    
    # Upload Player Activity
    print(f"Uploading player_activity to s3://{bucket_name}/bronze/")
    s3.put_object(
        Bucket=bucket_name,
        Key=f"bronze/player_activity_{timestamp}.json",
        Body=json.dumps(player_activity_list, indent=2)
    )
    
    print(f"Data uploaded successfully at {timestamp}")


def lambda_handler(event, context):
    """
    Lambda handler - Entry point cho AWS Lambda Service
    
    Tên hàm PHẢI là lambda_handler (chỉ định trong Dockerfile)
    """
    try:
        print("Starting Bronze Layer Ingestion...")
        
        # 1. Generate mock data
        game_list, player_activity_list = generate_mock_data(1000)
        print(f"Generated {len(game_list)} games and {len(player_activity_list)} activities")
        
        # 2. Upload to S3 (Bronze layer)
        upload_to_s3(game_list, player_activity_list)
        
        # 3. Return success response
        response = {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Bronze layer ingestion successful!',
                'games_count': len(game_list),
                'activities_count': len(player_activity_list),
                'timestamp': datetime.now().isoformat()
            })
        }
        print(f"Response: {response}")
        return response
        
    except Exception as e:
        print(f"Error during ingestion: {str(e)}")
        error_response = {
            'statusCode': 500,
            'body': json.dumps({
                'message': 'Bronze layer ingestion failed!',
                'error': str(e)
            })
        }
        return error_response


# For local testing
if __name__ == "__main__":
    lambda_handler(None, None)