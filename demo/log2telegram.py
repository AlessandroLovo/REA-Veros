# '''
# Created on 2022-09-20

# @author: Alessandro Lovo
# '''
'''
This modules logs a message to telegram

When running from terminal:
```
python log2telegram.py "<message>" [<telegram chat ID> <telegram bot token>] [<telegram logging level>]
```
'''
import sys
import logging

sys.path.append('../')
import general_purpose.utilities as ut

if __name__ == '__main__':
    logger = logging.getLogger()
    logger.handlers = [logging.StreamHandler(sys.stdout)]
else:
    logger = logging.getLogger(__name__)
logger.level = logging.INFO

if __name__ == '__main__':
    logger.debug(str(sys.argv))
    msg = sys.argv[1].strip('"').replace('\\n', '\n')
    try:
        telegram_logging_level = sys.argv[4]
    except IndexError:
        telegram_logging_level = logging.INFO

    with ut.TelegramLogger(logger, *(sys.argv[2:])):
        logger.log(telegram_logging_level,msg)