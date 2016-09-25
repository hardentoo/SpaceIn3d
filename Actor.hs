{-# LANGUAGE OverloadedStrings #-}

module Actor where

import HGamer3D

import Data

import qualified Data.Text as T
import Control.Concurrent
import Control.Monad.Trans.Reader
import Control.Monad.Trans.State
import Control.Monad.IO.Class
import Control.Monad.Trans.Class
import Data.Unique


-- ACTORS
-- ------

-- define all messages in this program, high level between actors

data Message = InitActor | StopActor -- intialize and stop actor
             | InitMusic | StartMusic | StopMusic | PlayShot | PlayNoShot | PlayExplosion -- music actor
             | StartProgram | BuildDone | KeysPressed [T.Text] | SingleKey T.Text -- screen actor
             | InitKeys | PollKeys -- key input actor
             | FastCycle | SlowCycle 
             | BuildLevel | MoveLeft | MoveRight | Shoot | MovementCycle -- movement actor
             | RollRight | RollLeft | PitchUp | PitchDown -- flying control
             | YawLeft | YawRight 
             | MoreSpeed | LessSpeed | ZeroSpeed 
             | ResetCamPosition | RestoreCamPosition | SaveCamPosition
             | DisplayStatus | HideStatus | SetName T.Text | SetCount Int | SetMode T.Text -- status bar actor
             | ActualInvaderData GameData | ActualCanonData GameData | ActualCollData [Unique] -- send to collision detector actor
             | CanonStep GameData [Unique] | MoveStep GameData [Unique] | CollisionStep GameData GameData
             | CacheLevel GameData
             | AddCount Int
--             deriving (Show)

newtype Actor = Actor (MVar Message)

newActor :: IO Actor
newActor = do
    mv <- newEmptyMVar
    return (Actor mv)

type ReaderStateIO r s a = StateT s (ReaderT r IO) a

runActor :: Actor -> (Actor -> Message -> ReaderStateIO r s () ) -> r -> s -> IO ()
runActor a@(Actor mv) f ri si = do
    let loop mv s = do
            msg <- takeMVar mv
            (_, s') <- runReaderT (runStateT (f a msg) s) ri
            loop mv s'
    forkIO $ loop mv si
    sendMsg a InitActor

stopActor a = sendMsg a StopActor

sendMsg :: Actor -> Message -> IO ()
sendMsg (Actor mv) m = putMVar mv m

